require "rails_helper"

RSpec.describe "Admin review queue", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:lifter) { create(:user) }
  let!(:held_lift) { create(:lift, user: lifter, exercise: :squat, weight_lifted: 300) }

  it "is hidden from non-admins" do
    sign_in_as(lifter)

    get admin_lifts_path
    expect(response).to have_http_status(:not_found)

    patch approve_admin_lift_path(held_lift)
    expect(response).to have_http_status(:not_found)
    expect(held_lift.reload).to be_pending
  end

  it "sends visitors to sign in" do
    get admin_lifts_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "as an admin" do
    before { sign_in_as(admin) }

    it "lists lifts waiting for review" do
      create(:lift, user: lifter, exercise: :bench, weight_lifted: 100) # below diamond: never queued

      get admin_lifts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{lifter.username}")
      expect(response.body).to include("Pending (1)")
      expect(response.body).not_to include("Bench")
    end

    it "approves a lift, which then counts toward the lifter's rank" do
      expect(lifter.best_lift(:squat)).to be_nil

      patch approve_admin_lift_path(held_lift)

      expect(response).to redirect_to(admin_lifts_path)
      expect(held_lift.reload).to be_approved
      expect(lifter.best_lift(:squat)).to eq(held_lift)
    end

    it "rejects a lift" do
      patch reject_admin_lift_path(held_lift)

      expect(held_lift.reload).to be_rejected
      expect(lifter.best_lift(:squat)).to be_nil

      get admin_lifts_path(status: "rejected")
      expect(response.body).to include("@#{lifter.username}")
    end

    it "deletes any lift" do
      expect { delete admin_lift_path(held_lift) }.to change(Lift, :count).by(-1)
    end
  end
end
