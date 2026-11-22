
require "uri"

module Billetto
  class Importer
    class PaginationError < StandardError; end

    def initialize(client: Client.new)
      @client = client
    end

    def import(limit: Client::DEFAULT_LIMIT)
      imported_count = 0
      skipped_count = 0
      total = 0
      after = nil
      seen_cursors = []

      loop do
        response = client.fetch_events(limit: limit, after: after)

        response.fetch("data").each do |event_data|
          unless importable?(event_data)
            skipped_count += 1
            next
          end

          import_event(event_data)
          imported_count += 1
        end

        total = response.fetch("total")

        break unless response.fetch("has_more")

        after = extract_next_cursor(response)

        if seen_cursors.include?(after)
          raise PaginationError, "Billetto returned a repeated pagination cursor"
        end

        seen_cursors << after
      end

      {
        imported_count: imported_count,
        skipped_count: skipped_count,
        total: total,
        has_more: false
      }
    end

    private

    attr_reader :client

    def importable?(event_data)
      event_data["id"].present? &&
        event_data["title"].present? &&
        event_data["startdate"].present?
    end

    def import_event(event_data)
      Event.find_or_initialize_by(
        billetto_id: event_data.fetch("id")
      ).update!(
        title: event_data.fetch("title"),
        description: event_data["description"],
        url: event_data["url"],
        image_url: event_data["image_link"],
        starts_at: event_data["startdate"],
        ends_at: event_data["enddate"]
      )
    end

    def extract_next_cursor(response)
      next_url = response["next_url"]

      raise PaginationError, "Missing next_url in Billetto response" if next_url.blank?

      uri = URI.parse(next_url)

      unless uri.host == "billetto.dk" &&
             uri.path == "/api/v3/public/events"
        raise PaginationError, "Unexpected Billetto pagination URL"
      end

      cursor = URI.decode_www_form(uri.query.to_s).to_h["after"]

      raise PaginationError, "Missing pagination cursor" if cursor.blank?

      cursor
    rescue URI::InvalidURIError
      raise PaginationError, "Invalid Billetto pagination URL"
    end
  end
end
