# Sidekiq Configuration Example for Rayces Booking Platform
# This file demonstrates how to configure Sidekiq for background job processing

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  
  # Set concurrency based on environment
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
  
  # Configure queues with priorities
  config.queues = %w[critical high default low]
  
  # Global error handlers
  config.error_handlers << proc do |ex, ctx|
    Rails.logger.error "Sidekiq error: #{ex.class} - #{ex.message}"
    Rails.logger.error ex.backtrace.join("\n")
    
    # You can add error reporting here (e.g., Sentry, Rollbar)
    # Sentry.capture_exception(ex) if defined?(Sentry)
  end
  
  # Lifecycle hooks
  config.on(:startup) do
    Rails.logger.info "Sidekiq server started"
  end
  
  config.on(:quiet) do
    Rails.logger.info "Sidekiq server quieting"
  end
  
  config.on(:shutdown) do
    Rails.logger.info "Sidekiq server shutting down"
  end
  
  # Configure retries exhausted handler
  config.default_retries_exhausted = -> (job, ex) do
    Rails.logger.error "Job #{job['class']} with args #{job['args']} failed permanently after #{job['retry_count']} retries"
    # You can add dead letter queue handling here
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# For Rails integration
Rails.application.config.active_job.queue_adapter = :sidekiq

# config/routes.rb - Mount Sidekiq Web UI
require 'sidekiq/web'

Rails.application.routes.draw do
  # Protect Sidekiq web UI in production
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == ENV['SIDEKIQ_WEB_USERNAME'] && password == ENV['SIDEKIQ_WEB_PASSWORD']
    end
  end
  
  mount Sidekiq::Web => '/sidekiq'
  
  # Your other routes...
end

# app/workers/application_worker.rb
class ApplicationWorker
  include Sidekiq::Worker
  include ActsAsTenant::WorkerExtensions
  
  # Default options for all workers
  sidekiq_options retry: 5, backtrace: true
  
  # Custom retry logic
  sidekiq_retry_in do |count, exception|
    case exception
    when ActiveRecord::RecordNotFound
      :discard # Don't retry for missing records
    when Net::TimeoutError
      10 * count # Exponential backoff for timeouts
    else
      30 # Default retry after 30 seconds
    end
  end
  
  # Handle retries exhausted
  sidekiq_retries_exhausted do |job, exception|
    Rails.logger.error "Job #{job['class']} permanently failed: #{exception.message}"
    # Handle permanent failures here
  end
end

# app/workers/appointment_reminder_worker.rb
class AppointmentReminderWorker < ApplicationWorker
  queue_as :high
  
  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    
    # Send reminder email
    AppointmentMailer.reminder(appointment).deliver_now
    
    # Log the action
    Rails.logger.info "Sent reminder for appointment #{appointment.id}"
  end
end

# app/workers/report_generation_worker.rb
class ReportGenerationWorker < ApplicationWorker
  queue_as :low
  sidekiq_options retry: 3, backtrace: 20
  
  def perform(organization_id, report_type, date_range)
    # Generate reports in background
    ActsAsTenant.with_tenant(Organization.find(organization_id)) do
      case report_type
      when 'appointments'
        generate_appointments_report(date_range)
      when 'students'
        generate_students_report(date_range)
      else
        raise ArgumentError, "Unknown report type: #{report_type}"
      end
    end
  end
  
  private
  
  def generate_appointments_report(date_range)
    # Report generation logic
    appointments = Appointment.where(created_at: date_range)
    # Generate and save report
  end
  
  def generate_students_report(date_range)
    # Report generation logic
    students = Student.where(created_at: date_range)
    # Generate and save report
  end
end

# app/workers/email_notification_worker.rb
class EmailNotificationWorker < ApplicationWorker
  queue_as :default
  
  def perform(notification_type, recipient_id, data = {})
    recipient = User.find(recipient_id)
    
    case notification_type
    when 'appointment_confirmed'
      AppointmentMailer.confirmed(recipient, data[:appointment_id]).deliver_now
    when 'appointment_cancelled'
      AppointmentMailer.cancelled(recipient, data[:appointment_id]).deliver_now
    when 'password_reset'
      UserMailer.password_reset(recipient, data[:token]).deliver_now
    else
      raise ArgumentError, "Unknown notification type: #{notification_type}"
    end
  end
end

# app/workers/data_cleanup_worker.rb
class DataCleanupWorker < ApplicationWorker
  queue_as :low
  sidekiq_options retry: 2
  
  def perform
    # Clean up old data across all tenants
    Organization.find_each do |organization|
      ActsAsTenant.with_tenant(organization) do
        cleanup_expired_appointments
        cleanup_old_logs
      end
    end
  end
  
  private
  
  def cleanup_expired_appointments
    # Delete cancelled appointments older than 30 days
    Appointment.cancelled.where('updated_at < ?', 30.days.ago).destroy_all
  end
  
  def cleanup_old_logs
    # Clean up old audit logs if you have them
    # AuditLog.where('created_at < ?', 90.days.ago).destroy_all
  end
end

# app/workers/webhook_worker.rb
class WebhookWorker < ApplicationWorker
  queue_as :critical
  sidekiq_options retry: 10, backtrace: true
  
  # Custom retry schedule for webhooks
  sidekiq_retry_in do |count, exception|
    case count
    when 1..3
      10 # Retry quickly for first few attempts
    when 4..6
      300 # 5 minutes
    when 7..10
      3600 # 1 hour for later attempts
    else
      :discard
    end
  end
  
  def perform(webhook_url, payload, organization_id)
    ActsAsTenant.with_tenant(Organization.find(organization_id)) do
      response = HTTP.post(webhook_url, json: payload)
      
      unless response.status.success?
        raise "Webhook failed with status #{response.status}"
      end
      
      Rails.logger.info "Webhook sent successfully to #{webhook_url}"
    end
  end
end

# lib/tasks/sidekiq.rake
namespace :sidekiq do
  desc "Start Sidekiq with proper configuration"
  task start: :environment do
    system("bundle exec sidekiq -C config/sidekiq.yml -e #{Rails.env}")
  end
  
  desc "Stop all Sidekiq processes"
  task stop: :environment do
    system("bundle exec sidekiqctl stop tmp/pids/sidekiq.pid")
  end
  
  desc "Restart Sidekiq"
  task restart: [:stop, :start]
  
  desc "Clear all Sidekiq queues"
  task clear: :environment do
    Sidekiq.redis { |conn| conn.flushdb }
    puts "All Sidekiq queues cleared"
  end
  
  desc "Show Sidekiq stats"
  task stats: :environment do
    stats = Sidekiq::Stats.new
    puts "Processed: #{stats.processed}"
    puts "Failed: #{stats.failed}"
    puts "Enqueued: #{stats.enqueued}"
    puts "Scheduled: #{stats.scheduled_size}"
    puts "Retry: #{stats.retry_size}"
    puts "Dead: #{stats.dead_size}"
  end
end

# config/sidekiq.yml
---
:concurrency: 5
:pidfile: tmp/pids/sidekiq.pid
:logfile: log/sidekiq.log
:queues:
  - critical
  - high
  - default
  - low

# Production configuration
production:
  :concurrency: 25
  :pidfile: tmp/pids/sidekiq.pid
  :logfile: log/sidekiq.log
  :queues:
    - [critical, 8]
    - [high, 6]
    - [default, 4]
    - [low, 2]

# Development configuration
development:
  :concurrency: 3
  :pidfile: tmp/pids/sidekiq.pid
  :logfile: log/sidekiq.log
  :queues:
    - critical
    - high
    - default
    - low

# Test configuration
test:
  :concurrency: 1
  :pidfile: tmp/pids/sidekiq.pid
  :logfile: log/sidekiq.log
  :queues:
    - critical
    - high
    - default
    - low

# config/schedule.rb (for recurring jobs with whenever gem)
every 1.hour do
  runner "AppointmentReminderWorker.perform_async"
end

every 1.day, at: '2:00 am' do
  runner "DataCleanupWorker.perform_async"
end

every 1.week, at: '3:00 am' do
  runner "ReportGenerationWorker.perform_async(nil, 'weekly_summary', 1.week.ago..Time.current)"
end

# docker-compose.yml addition for Redis
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

volumes:
  redis_data: