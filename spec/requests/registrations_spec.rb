require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /registrations/new" do
    it "offers leaderboard listing, ticked by default" do
      get new_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/type="checkbox"[^>]*checked="checked"[^>]*name="user\[public_profile\]"|name="user\[public_profile\]"[^>]*checked="checked"/)
    end
  end

  describe "POST /registrations" do
    let(:valid_params) do
      { email_address: "new@example.com", username: "new_lifter", password: "password123", sex: "male",
        weight_unit: "kg", public_profile: "1", time_zone: "America/Chicago" }
    end

    it "creates a user, signs them in, and redirects to the dashboard" do
      post registrations_path, params: { user: valid_params }

      expect(response).to redirect_to(dashboard_path)
      user = User.find_by(email_address: "new@example.com")
      expect(user.username).to eq("new_lifter")
      expect(user.time_zone).to eq("America/Chicago")
      expect(user).to be_public_profile
      expect(cookies["session_id"]).to be_present
    end

    it "falls back to UTC when the browser's time zone is missing or unknown" do
      post registrations_path, params: { user: valid_params.merge(time_zone: "Nowhere/Special") }

      expect(User.find_by(email_address: "new@example.com").time_zone).to eq("Etc/UTC")
    end

    it "respects opting out of the leaderboard" do
      post registrations_path, params: { user: valid_params.merge(public_profile: "0") }

      expect(User.find_by(email_address: "new@example.com")).not_to be_public_profile
    end

    it "re-renders the form with errors for invalid input" do
      post registrations_path, params: { user: valid_params.merge(email_address: "") }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires a username" do
      post registrations_path, params: { user: valid_params.merge(username: "") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Username can&#39;t be blank")
    end
  end
end
