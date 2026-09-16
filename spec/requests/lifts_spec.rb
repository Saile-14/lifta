require "rails_helper"

RSpec.describe "Lifts", type: :request do
  describe "when unauthenticated" do
    it "redirects to sign in" do
      get lifts_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "when authenticated" do
    let(:user) { create(:user) }

    before do
      create(:bodyweight_entry, user: user, kilograms: 80)
      sign_in_as(user)
    end

    it "logs a lift in kg and snapshots the user's current bodyweight" do
      post lifts_path, params: { lift: { exercise: "squat", weight: "150", unit: "kg", reps: "1" } }

      expect(response).to redirect_to(lifts_path)
      lift = user.lifts.last
      expect(lift.exercise).to eq("squat")
      expect(lift.weight_lifted).to eq(150)
      expect(lift.bodyweight_kg).to eq(80)
    end

    it "converts a pound entry to canonical kilograms" do
      post lifts_path, params: { lift: { exercise: "bench", weight: "220.462", unit: "lb", reps: "1" } }

      expect(user.lifts.last.weight_lifted).to be_within(0.01).of(100.0)
    end

    it "re-renders the form for invalid input" do
      post lifts_path, params: { lift: { exercise: "squat", weight: "0", unit: "kg", reps: "1" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
