class BillettoImportJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "billetto:import:lock"

  retry_on Billetto::Client::Error,
           Billetto::Importer::PaginationError,
           wait: 30.seconds,
           attempts: 3

  def perform
    lock = RedisLock.new(key: LOCK_KEY)

    unless lock.acquire
      Rails.logger.info(
        "[BillettoImportJob] Another import is already running. Skipping."
      )
      return
    end

    begin
      Rails.logger.info("[BillettoImportJob] Starting event import")

      result = Billetto::Importer.new.import

      Rails.logger.info(
        "[BillettoImportJob] Import completed. " \
        "Imported: #{result[:imported_count]}, " \
        "Skipped: #{result[:skipped_count]}, " \
        "Total: #{result[:total]}"
      )

      result
    ensure
      lock.release
      Rails.logger.info("[BillettoImportJob] Import lock released")
    end
  end
end