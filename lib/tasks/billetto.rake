
namespace :billetto do
  desc "Import events from Billetto API"

  task import_events: :environment do
    puts "Starting Billetto event import..."

    result = Billetto::Importer.new.import

    puts "Billetto import completed!"
    puts "Events processed: #{result[:imported_count]}"
    puts "Events skipped: #{result[:skipped_count]}"
    puts "Total events reported by API: #{result[:total]}"
    puts "More events available: #{result[:has_more]}"
  rescue Billetto::Client::Error, Billetto::Importer::PaginationError,
         ActiveRecord::RecordInvalid => e
    warn "Billetto import failed: #{e.class}: #{e.message}"
    exit 1
  end

  desc "Enqueue Billetto event import as a background job"

  task enqueue_import: :environment do
    job = BillettoImportJob.perform_later

    puts "Billetto import enqueued successfully!"
    puts "Job ID: #{job.job_id}"
    puts "Queue: #{job.queue_name}"
  rescue StandardError => e
    warn "Failed to enqueue Billetto import: #{e.class}: #{e.message}"
    exit 1
  end
end
