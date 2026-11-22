
require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events" do
    it "returns http success" do
      get events_path

      expect(response).to have_http_status(:success)
    end

    it "displays upcoming events" do
      upcoming_event = Event.create!(
        billetto_id: "upcoming-123",
        title: "Upcoming Music Festival",
        starts_at: 2.days.from_now
      )

      get events_path

      expect(response.body).to include(upcoming_event.title)
    end

    it "does not display past events" do
      Event.create!(
        billetto_id: "past-123",
        title: "Past Music Festival",
        starts_at: 2.days.ago
      )

      get events_path

      expect(response.body).not_to include("Past Music Festival")
    end

    it "displays a maximum of 50 upcoming events" do
      events = 51.times.map do |index|
        Event.create!(
          billetto_id: "event-#{index}",
          title: "Festival #{index}",
          starts_at: (index + 1).days.from_now
        )
      end

      get events_path

      expect(response.body).to include(events.first.title)
      expect(response.body).to include(events[49].title)
      expect(response.body).not_to include(events.last.title)
    end

    it "displays the correct like and dislike counts" do
      event = Event.create!(
        billetto_id: "vote-test-123",
        title: "Voting Test Event",
        starts_at: 2.days.from_now
      )

      2.times do |index|
        EventVote.create!(
          event_id: event.billetto_id,
          user_id: "like-user-#{index}",
          vote: "like"
        )
      end

      EventVote.create!(
        event_id: event.billetto_id,
        user_id: "dislike-user",
        vote: "dislike"
      )

      get events_path

      expect(response.body).to include("Likes:")
      expect(response.body).to include("Dislikes:")
      expect(response.body).to include("<strong>2</strong>")
      expect(response.body).to include("<strong>1</strong>")
    end
  end

  describe "POST /events/:event_id/like" do
    let!(:event) do
      Event.create!(
        billetto_id: "auth-test-123",
        title: "Authentication Test Event",
        starts_at: 2.days.from_now
      )
    end

    context "when the user is unauthenticated" do
      it "redirects the user" do
        post event_like_path(event)

        expect(response).to have_http_status(:redirect)
      end

      it "does not create a vote" do
        expect {
          post event_like_path(event)
        }.not_to change(EventVote, :count)
      end
    end

    context "when the user is authenticated" do
      let(:user_id) { "user_test_123" }

      before do
        authenticated_clerk = Clerk::Proxy.new(
          session_claims: { "sub" => user_id }
        )

        allow_any_instance_of(VotingController)
          .to receive(:clerk)
          .and_return(authenticated_clerk)
      end

      it "creates a like vote for the authenticated user" do
        expect {
          post event_like_path(event)
        }.to change(EventVote, :count).by(1)

        vote = EventVote.find_by!(
          event_id: event.billetto_id,
          user_id: user_id
        )

        expect(vote.vote).to eq("like")
      end

      it "redirects to the events page after voting" do
        post event_like_path(event)

        expect(response).to redirect_to(events_path)
      end
    end
  end
  describe "POST /events/:event_id/dislike" do
    let!(:event) do
      Event.create!(
        billetto_id: "auth-test-456",
        title: "Authentication Test Event",
        starts_at: 2.days.from_now
      )
    end

    context "when the user is unauthenticated" do
      it "redirects the user" do
        post event_dislike_path(event)

        expect(response).to have_http_status(:redirect)
      end

      it "does not create a vote" do
        expect {
          post event_dislike_path(event)
        }.not_to change(EventVote, :count)
      end
    end

    context "when the user is authenticated" do
      let(:user_id) { "user_test_456" }

      before do
        authenticated_clerk = Clerk::Proxy.new(
          session_claims: { "sub" => user_id }
        )

        allow_any_instance_of(VotingController)
          .to receive(:clerk)
          .and_return(authenticated_clerk)
      end

      it "creates a dislike vote for the authenticated user" do
        expect {
          post event_dislike_path(event)
        }.to change(EventVote, :count).by(1)

        vote = EventVote.find_by!(
          event_id: event.billetto_id,
          user_id: user_id
        )

        expect(vote.vote).to eq("dislike")
      end

      it "redirects to the events page after voting" do
        post event_dislike_path(event)

        expect(response).to redirect_to(events_path)
      end

      it "updates an existing like vote to dislike" do
        expect {
          post event_like_path(event)
          post event_dislike_path(event)
        }.to change(EventVote, :count).by(1)

        vote = EventVote.find_by!(
          event_id: event.billetto_id,
          user_id: user_id
        )

        expect(vote.vote).to eq("dislike")
      end
    end
  end
end
