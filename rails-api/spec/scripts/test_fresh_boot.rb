#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Fresh Boot Scenario
# 
# This script tests that the Rails application can boot successfully from a fresh state,
# including database creation and migrations, without encountering NameError or other
# initialization issues. This is critical for Kubernetes deployments and CI/CD pipelines.
#
# Usage:
#   bundle exec ruby spec/scripts/test_fresh_boot.rb
#   
# Options:
#   --skip-drop    Skip dropping databases (useful if they don't exist)
#   --verbose      Show detailed output from each command
#   --help         Show this help message

require 'optparse'
begin
  require 'colorize'
rescue LoadError
  # Colorize gem is optional
end

# Helper to print colored output (falls back to plain text if colorize not available)
def print_status(message, status = :info)
  prefix = case status
           when :success then "✅"
           when :error then "❌"
           when :warning then "⚠️"
           when :info then "ℹ️"
           else "•"
           end
  
  if defined?(Colorize)
    color = case status
            when :success then :green
            when :error then :red
            when :warning then :yellow
            when :info then :blue
            else :default
            end
    puts "#{prefix} #{message}".colorize(color)
  else
    puts "#{prefix} #{message}"
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bundle exec ruby spec/scripts/test_fresh_boot.rb [options]"

  opts.on("--skip-drop", "Skip dropping databases") do
    options[:skip_drop] = true
  end

  opts.on("-v", "--verbose", "Show detailed output") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Test configuration
class FreshBootTest
  attr_reader :options, :errors

  def initialize(options = {})
    @options = options
    @errors = []
  end

  def run
    print_status "=== Testing Fresh Boot Scenario ===", :info
    puts "Environment: #{ENV['RAILS_ENV'] || 'development'}"
    puts "Database: #{ENV['DATABASE_URL'] || 'Using database.yml'}"
    puts

    # Run test steps
    drop_databases unless options[:skip_drop]
    test_db_create
    test_db_migrate
    test_rails_runner
    test_initializers
    test_server_boot

    # Report results
    if errors.empty?
      print_status "=== All tests passed! Fresh boot works correctly ===", :success
      exit 0
    else
      print_status "=== Tests failed with #{errors.length} error(s) ===", :error
      errors.each_with_index do |error, i|
        puts "  #{i + 1}. #{error}"
      end
      exit 1
    end
  end

  private

  def drop_databases
    print_status "Step 1: Dropping databases...", :info
    
    # Use DISABLE_DATABASE_ENVIRONMENT_CHECK to allow dropping in any environment
    result = run_command("bundle exec rails db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1")
    
    if result[:success] || result[:output].include?("does not exist")
      print_status "  Databases dropped (or didn't exist)", :success
    else
      print_status "  Warning: Could not drop databases - #{result[:error]}", :warning
    end
  end

  def test_db_create
    print_status "Step 2: Testing rails db:create...", :info
    
    result = run_command("bundle exec rails db:create")
    
    if result[:success]
      print_status "  db:create succeeded without crashes", :success
    else
      errors << "db:create failed: #{result[:error]}"
      print_status "  db:create failed", :error
    end
  end

  def test_db_migrate
    print_status "Step 3: Testing rails db:migrate...", :info
    
    result = run_command("bundle exec rails db:migrate")
    
    if result[:success]
      print_status "  db:migrate succeeded", :success
    else
      errors << "db:migrate failed: #{result[:error]}"
      print_status "  db:migrate failed", :error
    end
  end

  def test_rails_runner
    print_status "Step 4: Testing rails runner with Organization model...", :info
    
    # Test that models can be loaded and queried
    test_code = <<~RUBY
      require 'boot_guard' if File.exist?('lib/boot_guard.rb')
      
      # Check if Organization model is available
      if defined?(Organization) && Organization.table_exists?
        puts "Organization count: \#{Organization.count}"
        
        # Test creating an organization
        org = Organization.create!(name: 'Test Boot Org', subdomain: 'test-boot')
        puts "Created organization: \#{org.name}"
        
        # Test acts_as_tenant
        ActsAsTenant.current_tenant = org
        puts "Tenant set: \#{ActsAsTenant.current_tenant&.name}"
        
        # Clean up
        org.destroy
        puts "Test organization cleaned up"
      else
        puts "ERROR: Organization model not available!"
        exit 1
      end
    RUBY
    
    # Write test code to a temporary file
    require 'tempfile'
    tempfile = Tempfile.new(['rails_runner_test', '.rb'])
    begin
      tempfile.write(test_code)
      tempfile.close
      
      result = run_command("bundle exec rails runner #{tempfile.path}")
      
      if result[:success] && !result[:output].include?("ERROR")
        print_status "  Rails runner succeeded - models loaded correctly", :success
      else
        errors << "Rails runner failed: #{result[:error] || 'Model loading error'}"
        print_status "  Rails runner failed", :error
      end
    ensure
      tempfile.unlink
    end
  end

  def test_initializers
    print_status "Step 5: Testing initializer loading...", :info
    
    # Test that initializers don't crash during boot
    test_code = <<~RUBY
      # Check acts_as_tenant configuration
      if defined?(ActsAsTenant)
        puts "ActsAsTenant configured: \#{ActsAsTenant.configuration.require_tenant}"
      else
        puts "ERROR: ActsAsTenant not loaded!"
        exit 1
      end
      
      # Check if BootGuard is available
      if defined?(BootGuard)
        puts "BootGuard available: db_ready=\#{BootGuard.db_ready?}"
      end
    RUBY
    
    # Write test code to a temporary file
    require 'tempfile'
    tempfile = Tempfile.new(['initializer_test', '.rb'])
    begin
      tempfile.write(test_code)
      tempfile.close
      
      result = run_command("bundle exec rails runner #{tempfile.path}")
      
      if result[:success] && !result[:output].include?("ERROR")
        print_status "  Initializers loaded correctly", :success
      else
        errors << "Initializer test failed: #{result[:error] || 'Initializer loading error'}"
        print_status "  Initializer test failed", :error
      end
    ensure
      tempfile.unlink
    end
  end

  def test_server_boot
    print_status "Step 6: Testing Rails server boot...", :info
    
    # Start server and immediately kill it to test boot
    server_pid = nil
    
    begin
      # Start server in background
      server_pid = spawn(
        "bundle exec rails server -p 4001",
        out: options[:verbose] ? STDOUT : '/dev/null',
        err: options[:verbose] ? STDERR : '/dev/null'
      )
      
      # Wait a bit for server to start
      sleep 3
      
      # Check if process is still running
      process_alive = begin
        Process.kill(0, server_pid)
        true
      rescue
        false
      end
      
      if process_alive
        print_status "  Rails server booted successfully", :success
      else
        errors << "Rails server failed to start"
        print_status "  Rails server failed to start", :error
      end
    ensure
      # Clean up server process
      if server_pid
        Process.kill("TERM", server_pid) rescue nil
        Process.wait(server_pid) rescue nil
      end
    end
  end

  def run_command(command)
    output = ""
    error = ""
    
    if options[:verbose]
      puts "  Running: #{command}"
    end
    
    require 'open3'
    stdout, stderr, status = Open3.capture3(command)
    
    output = stdout
    error = stderr
    
    if options[:verbose] && !output.empty?
      puts "  Output: #{output}"
    end
    
    if options[:verbose] && !error.empty?
      puts "  Error: #{error}"
    end
    
    {
      success: status.success?,
      output: output,
      error: error,
      status: status
    }
  end
end

# Run the test
FreshBootTest.new(options).run