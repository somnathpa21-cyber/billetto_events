
require "rails_helper"
require "webmock/rspec"

RSpec.describe Billetto::Client do
  let(:api_keypair) { "test-api-keypair" }
  let(:client) { described_class.new(api_keypair: api_keypair) }

  let(:api_url) do
    "https://billetto.dk/api/v3/public/events"
  end

  let(:api_response) do
    {
      object: "list",
      data: [
        {
          id: "2099841",
          title: "Test Event",
          description: "Test event description",
          image_link: "https://example.com/image.jpg",
          startdate: "2026-12-03T16:00:00Z",
          enddate: "2026-12-03T17:00:00Z"
        }
      ],
      total: 1,
      has_more: false
    }
  end

  describe "#fetch_events" do
    context "when the API request succeeds" do
      before do
        stub_request(:get, api_url)
          .with(
            query: { "limit" => "10" },
            headers: {
              "Api-Keypair" => api_keypair,
              "Accept" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the parsed events response" do
        result = client.fetch_events(limit: 10)

        expect(result["data"].size).to eq(1)
        expect(result["data"].first["title"]).to eq("Test Event")
        expect(result["total"]).to eq(1)
      end
    end

    context "when authentication fails" do
      before do
        stub_request(:get, api_url)
        .with(query: { "limit" => "10" })
        .to_return(status: 401, body: "Unauthorized")
      end

      it "raises an authentication error" do
        expect {
          client.fetch_events
        }.to raise_error(Billetto::Client::AuthenticationError)
      end
    end

    context "when the API returns a server error" do
      before do
        stub_request(:get, api_url)
        .with(query: { "limit" => "10" })
        .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises an API error" do
        expect {
          client.fetch_events
        }.to raise_error(Billetto::Client::ApiError)
      end
    end

    context "when the API returns invalid JSON" do
      before do
        stub_request(:get, api_url)
        .with(query: { "limit" => "10" })
        .to_return(status: 200, body: "invalid-json")
      end

      it "raises an invalid response error" do
        expect {
          client.fetch_events
        }.to raise_error(Billetto::Client::InvalidResponseError)
      end
    end

    context "when the API response has an unexpected structure" do
      before do
        stub_request(:get, api_url)
        .with(query: { "limit" => "10" })
        .to_return(
          status: 200,
          body: { object: "list", data: nil }.to_json
        )
      end

      it "raises an invalid response error" do
        expect {
          client.fetch_events
        }.to raise_error(Billetto::Client::InvalidResponseError)
      end
    end

    context "when requesting the next page" do
      before do
        stub_request(:get, api_url)
          .with(query: { "limit" => "5", "after" => "2098424" })
          .to_return(
            status: 200,
            body: api_response.to_json
          )
      end

      it "sends the pagination cursor" do
        client.fetch_events(limit: 5, after: "2098424")

        expect(
          a_request(:get, api_url)
            .with(query: { "limit" => "5", "after" => "2098424" })
        ).to have_been_made.once
      end
    end
  end

  describe "initialization" do
    it "raises an authentication error when the API key is missing" do
      expect {
        described_class.new(api_keypair: nil)
      }.to raise_error(Billetto::Client::AuthenticationError)
    end
  end
end
