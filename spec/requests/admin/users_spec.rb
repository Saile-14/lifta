require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:lifter) { create(:user, username: "cheater", email_address: "cheater@example.com") }

  before do
    create(:bodyweight_entry, user: lifter)
    create(:lift, user: lifter)
  end

  it "is hidden from non-admins" do
    sign_in_as(lifter)

    get admin_users_path
    expect(response).to have_http_status(:not_found)

    delete admin_user_path(admin)
    expect(response).to have_http_status(:not_found)
    expect(admin.reload).to be_persisted
  end

  describe "as an admin" do
    before { sign_in_as(admin) }

    it "lists and searches users" do
      create(:user, username: "someone_else")

      get admin_users_path(q: "cheat")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@cheater")
      expect(response.body).not_to include("@someone_else")
    end

    it "shows a user's lifts" do
      get admin_user_path(lifter)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("cheater@example.com")
      expect(response.body).to include("Squat")
    end

    it "deletes a user along with their lifts, bodyweight log and sessions" do
      expect { delete admin_user_path(lifter) }
        .to change(User, :count).by(-1)
        .and change(Lift, :count).by(-1)
        .and change(BodyweightEntry, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end

    it "won't delete the admin's own account" do
      expect { delete admin_user_path(admin) }.not_to change(User, :count)
      expect(flash[:alert]).to include("can't delete your own account")
    end
  end
end
