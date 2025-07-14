# app/workers/application_worker.rb
class ApplicationWorker
  include Sidekiq::Worker
  
  # Default options for all workers
  sidekiq_options retry: 3, backtrace: true
  
  # Ensure tenant context is preserved in background jobs
  # This is handled automatically by ActsAsTenant::Sidekiq middleware
  
  protected
  
  def log_info(message)
    logger.info "[#{self.class.name}] #{message}"
  end
  
  def log_error(message, exception = nil)
    logger.error "[#{self.class.name}] #{message}"
    logger.error exception.backtrace.join("\n") if exception
  end
  
  def with_error_handling
    yield
  rescue StandardError => e
    log_error("Error in #{self.class.name}: #{e.message}", e)
    raise e # Re-raise to trigger Sidekiq retry
  end
end