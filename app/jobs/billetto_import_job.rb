
class BillettoImportJob < ApplicationJob
  queue_as :default

  retry_on Billetto::Client::Error,
           Billetto::Importer::PaginationError,
           wait: 30.seconds,
           attempts: 3

  def perform
    Rails.logger.info("[BillettoImportJob] Starting event import")

    result = Billetto::Importer.new.import

    Rails.logger.info(
      "[BillettoImportJob] Import completed. " \
      "Imported: #{result[:imported_count]}, " \
      "Skipped: #{result[:skipped_count]}, " \
      "Total: #{result[:total]}"
    )

    result
  end
end
