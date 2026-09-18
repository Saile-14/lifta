require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects unauthenticated visitors to sign in" do
    get dashboard_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "when signed in" do
    let(:user) { create(:user) }

    before do
      create(:bodyweight_entry, user: user, kilograms: 80)
      sign_in_as(user)
    end

    it "shows the rank per exercise with the best lift and the next target" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 120, reps: 3)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Squat")
      expect(response.body).to include("Silver · 42.3%")
      expect(response.body).to include("Next: Gold at 187.5 kg, or 162.5 kg × 5")
      expect(response.body).to include("Log bench and deadlift for an overall rank.")
    end

    it "shows the overall rank and DOTS total once all three lifts are in" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 150)
      create(:lift, user: user, exercise: :bench, weight_lifted: 100)
      create(:lift, user: user, exercise: :deadlift, weight_lifted: 180)

      get dashboard_path

      expect(response.body).to include("DOTS total")
    end

    it "switches discipline" do
      create(:lift, user: user, exercise: :pull_up, weight_lifted: 0, reps: 10)

      get dashboard_path(discipline: "calisthenics")

      expect(response.body).to include("Your calisthenics ranks")
      expect(response.body).to include("Next: Gold at 15 reps")
    end

    it "mentions lifts waiting for review" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 300)

      get dashboard_path

      expect(response.body).to include("1 lift waiting for review")
    end
  end
end
