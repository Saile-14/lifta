require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user, username: "old_name") }

  it "requires signing in" do
    get settings_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "when signed in" do
    before { sign_in_as(user) }

    it "shows the settings form" do
      get settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("old_name")
    end

    it "updates username, units, time zone and leaderboard listing" do
      patch settings_path, params: { user: { username: "new_name", weight_unit: "lb", time_zone: "Europe/Berlin", public_profile: "1" } }

      expect(response).to redirect_to(settings_path)
      user.reload
      expect(user.username).to eq("new_name")
      expect(user).to be_lb
      expect(user.time_zone).to eq("Europe/Berlin")
      expect(user).to be_public_profile
    end

    it "re-renders with errors, without the rejected username leaking into the nav" do
      create(:user, username: "taken")

      patch settings_path, params: { user: { username: "taken" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Username has already been taken")
      expect(response.body).to include("@old_name")
    end

    it "doesn't let a user make themselves admin" do
      patch settings_path, params: { user: { admin: "1" } }

      expect(user.reload).not_to be_admin
    end
  end
end
