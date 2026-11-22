
require "rails_helper"

RSpec.describe "Events", type: :system do
  describe "Events listing" do
    it "displays upcoming events to visitors" do
      event = Event.create!(
        billetto_id: "browser-event-123",
        title: "Ruby Conference 2026",
        description: "A conference for Ruby developers",
        starts_at: 2.days.from_now
      )

      visit events_path

      expect(page).to have_content("Ruby Conference 2026")
      expect(page).to have_content("A conference for Ruby developers")
      expect(page).to have_content("Likes:")
      expect(page).to have_content("Dislikes:")
    end
  end
end
