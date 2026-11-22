
require "rails_helper"

RSpec.describe Billetto::Importer do
  let(:client) { instance_double(Billetto::Client) }
  let(:importer) { described_class.new(client: client) }

  let(:event_data) do
    {
      "id" => "2099841",
      "title" => "NADA cafe",
      "description" => "Test event description",
      "url" => "https://billetto.dk/e/test",
      "image_link" => "https://example.com/image.jpg",
      "startdate" => "2026-12-03T16:00:00Z",
      "enddate" => "2026-12-03T17:00:00Z"
    }
  end

  let(:api_response) do
    {
      "data" => [event_data],
      "total" => 1,
      "has_more" => false
    }
  end

  describe "#import" do
    before do
      allow(client).to receive(:fetch_events)
        .with(limit: 10, after: nil)
        .and_return(api_response)
    end

    context "when API returns events" do
      it "imports events from the API response" do
        expect {
          importer.import(limit: 10)
        }.to change(Event, :count).by(1)

        event = Event.find_by!(billetto_id: "2099841")

        expect(event.title).to eq("NADA cafe")
        expect(event.description).to eq("Test event description")
        expect(event.url).to eq("https://billetto.dk/e/test")
        expect(event.image_url).to eq("https://example.com/image.jpg")
        expect(event.starts_at).to eq(Time.zone.parse("2026-12-03T16:00:00Z"))
      end

      it "does not create duplicate events when importing again" do
        importer.import(limit: 10)

        expect {
          importer.import(limit: 10)
        }.not_to change(Event, :count)
      end

      it "updates an existing event" do
        Event.create!(
          billetto_id: "2099841",
          title: "Old title",
          starts_at: 2.days.from_now
        )

        importer.import(limit: 10)

        event = Event.find_by!(billetto_id: "2099841")

        expect(event.title).to eq("NADA cafe")
        expect(event.description).to eq("Test event description")
      end

      it "returns import statistics" do
        result = importer.import(limit: 10)

        expect(result).to eq(
          imported_count: 1,
          skipped_count: 0,
          total: 1,
          has_more: false
        )
      end
    end

    context "when an event has missing required data" do
      it "skips events without a startdate" do
        event_without_startdate = event_data.merge("startdate" => nil)

        allow(client).to receive(:fetch_events)
          .with(limit: 10, after: nil)
          .and_return(
            "data" => [event_without_startdate],
            "total" => 1,
            "has_more" => false
          )

        expect {
          importer.import(limit: 10)
        }.not_to change(Event, :count)

        result = importer.import(limit: 10)

        expect(result).to eq(
          imported_count: 0,
          skipped_count: 1,
          total: 1,
          has_more: false
        )
      end
    end

    context "when multiple pages are available" do
      let(:second_event_data) do
        event_data.merge(
          "id" => "2099842",
          "title" => "Second Event"
        )
      end

      let(:first_page) do
        {
          "data" => [event_data],
          "total" => 2,
          "has_more" => true,
          "next_url" => "https://billetto.dk/api/v3/public/events?after=2099841&limit=10"
        }
      end

      let(:second_page) do
        {
          "data" => [second_event_data],
          "total" => 2,
          "has_more" => false
        }
      end

      it "fetches and imports all pages" do
        expect(client).to receive(:fetch_events)
          .with(limit: 10, after: nil)
          .ordered
          .and_return(first_page)

        expect(client).to receive(:fetch_events)
          .with(limit: 10, after: "2099841")
          .ordered
          .and_return(second_page)

        result = importer.import(limit: 10)

        expect(Event.count).to eq(2)
        expect(result).to eq(
          imported_count: 2,
          skipped_count: 0,
          total: 2,
          has_more: false
        )
      end

      it "raises an error when next_url is missing" do
        allow(client).to receive(:fetch_events)
          .with(limit: 10, after: nil)
          .and_return(
            "data" => [event_data],
            "total" => 2,
            "has_more" => true
          )

        expect {
          importer.import(limit: 10)
        }.to raise_error(
          Billetto::Importer::PaginationError,
          "Missing next_url in Billetto response"
        )
      end
    end
  end
end
