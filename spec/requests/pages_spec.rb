require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET / when signed out" do
    it "shows the public landing page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lifta")
    end
  end

  describe "GET / when signed in" do
    it "redirects to the dashboard" do
      user = create(:user)
      sign_in_as(user)

      get root_path

      expect(response).to redirect_to(dashboard_path)
    end
  end
end
