require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "POST /registrations" do
    it "creates a user, signs them in, and redirects to the dashboard" do
      post registrations_path, params: {
        user: { email_address: "new@example.com", password: "password123", sex: "male", weight_unit: "kg" }
      }

      expect(response).to redirect_to(root_path)
      expect(User.find_by(email_address: "new@example.com")).to be_present
      expect(cookies["session_id"]).to be_present
    end

    it "re-renders the form with errors for invalid input" do
      post registrations_path, params: {
        user: { email_address: "", password: "password123", sex: "male" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
