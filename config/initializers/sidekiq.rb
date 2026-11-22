require "sidekiq/cron/job"
require "yaml"

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = Rails.root.join("config/schedule.yml")

    if File.exist?(schedule_file)
      schedule = YAML.safe_load_file(schedule_file)
      Sidekiq::Cron::Job.load_from_hash(schedule)

      Rails.logger.info("[Sidekiq] Billetto import schedule loaded")
    end
  end
end
