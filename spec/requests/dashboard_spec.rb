require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects unauthenticated visitors to sign in" do
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "shows the signed-in user's current rank per exercise" do
    user = create(:user)
    create(:bodyweight_entry, user: user, kilograms: 80)
    create(:lift, user: user, exercise: :squat, weight_lifted: 150, bodyweight_kg: 80)
    sign_in_as(user)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Squat")
  end
end
