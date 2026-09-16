require "rails_helper"

RSpec.describe "BodyweightEntries", type: :request do
  describe "when unauthenticated" do
    it "redirects to sign in" do
      get bodyweight_entries_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "when authenticated" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "logs a bodyweight entry, converting pounds to canonical kilograms" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "220.462", unit: "lb" } }

      expect(response).to redirect_to(bodyweight_entries_path)
      expect(user.bodyweight_entries.last.kilograms).to be_within(0.01).of(100.0)
    end

    it "stores a kg entry as-is" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "80", unit: "kg" } }

      expect(user.bodyweight_entries.last.kilograms).to eq(80.0)
    end

    it "re-renders the form for invalid input" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "-5", unit: "kg" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "lists the user's own entries" do
      create(:bodyweight_entry, user: user, kilograms: 81)
      get bodyweight_entries_path
      expect(response).to have_http_status(:ok)
    end
  end
end
