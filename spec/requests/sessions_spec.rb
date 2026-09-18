require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "signs in and out" do
    user = create(:user)

    sign_in_as(user)
    expect(response).to redirect_to(dashboard_url)

    delete session_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "password resets (off until outgoing mail is set up)" do
    it "doesn't offer a reset link on the sign-in page" do
      get new_session_path

      expect(response.body).not_to include("Forgot password?")
    end

    it "turns the reset pages away" do
      get new_password_path
      expect(response).to redirect_to(new_session_path)

      post passwords_path, params: { email_address: "someone@example.com" }
      expect(response).to redirect_to(new_session_path)
    end
  end
end
