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
      create(:bodyweight_entry, user: user, kilograms: 80, recorded_at: 1.hour.ago)
      sign_in_as(user)
    end

    def log_lift(**attributes)
      post lifts_path, params: { lift: { exercise: "squat", weight: "150", unit: "kg", reps: "1" }.merge(attributes) }
    end

    describe "logging a lift" do
      it "shows a form for each discipline" do
        get new_lift_path
        expect(response.body).to include("Squat")

        get new_lift_path(discipline: "weightlifting")
        expect(response.body).to include("Clean &amp; jerk")

        get new_lift_path(discipline: "calisthenics")
        expect(response.body).to include("Added weight (optional)")
      end

      it "logs a lift in kg, snapshots the current bodyweight, and shows the dashboard" do
        log_lift

        expect(response).to redirect_to(dashboard_path(discipline: "powerlifting"))
        lift = user.lifts.last
        expect(lift.exercise).to eq("squat")
        expect(lift.weight_lifted).to eq(150)
        expect(lift.bodyweight_kg).to eq(80)
      end

      it "converts a pound entry to canonical kilograms" do
        log_lift(exercise: "bench", weight: "220.462", unit: "lb")

        expect(user.lifts.last.weight_lifted).to be_within(0.01).of(100.0)
      end

      it "re-renders the form for invalid input" do
        log_lift(weight: "0")

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "scores a backdated lift at the bodyweight logged back then" do
        create(:bodyweight_entry, user: user, kilograms: 95, recorded_at: 60.days.ago)

        log_lift(lifted_at: 30.days.ago.to_date.iso8601)

        expect(user.lifts.last.bodyweight_kg).to eq(95)
      end

      it "uses a bodyweight typed into the form, and adds it to the bodyweight log" do
        log_lift(lifted_at: 10.days.ago.to_date.iso8601, bodyweight: "176.4", unit: "lb")

        expect(user.lifts.last.bodyweight_kg).to be_within(0.01).of(80.01)
        expect(user.bodyweight_entries.count).to eq(2)
      end

      it "explains that bodyweight is needed when there's none logged" do
        newcomer = create(:user)
        sign_in_as(newcomer)

        log_lift

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Bodyweight is needed to score this lift")
      end

      it "refuses sets too long to estimate a max from" do
        log_lift(reps: "15")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("can&#39;t be more than 10")
      end

      it "logs weightlifting and calisthenics lifts" do
        log_lift(exercise: "snatch", weight: "90", reps: "1")
        log_lift(exercise: "pull_up", weight: "", reps: "12")

        expect(user.lifts.pluck(:exercise)).to contain_exactly("snatch", "pull_up")
        expect(response).to redirect_to(dashboard_path(discipline: "calisthenics"))
      end
    end

    describe "rank feedback" do
      it "announces a lift's first rank" do
        log_lift(weight: "150")
        follow_redirect!

        expect(response.body).to include("Squat ranked: Silver")
      end

      it "celebrates a rank up" do
        create(:lift, user: user, exercise: :squat, weight_lifted: 150)

        log_lift(weight: "190")

        expect(flash[:notice]).to start_with("Rank up! Squat: Silver → Gold")
        expect(flash[:tier]).to eq(:gold)
      end

      it "calls out a new best within the same tier" do
        create(:lift, user: user, exercise: :squat, weight_lifted: 140)

        log_lift(weight: "150")

        expect(flash[:notice]).to start_with("New squat best: Silver")
      end

      it "announces the overall rank once all three lifts are in" do
        create(:lift, user: user, exercise: :squat, weight_lifted: 150)
        create(:lift, user: user, exercise: :bench, weight_lifted: 100)

        log_lift(exercise: "deadlift", weight: "180")

        expect(flash[:notice]).to include("Powerlifting overall: Silver")
      end

      it "holds a diamond-level lift for review" do
        log_lift(weight: "300")

        expect(user.lifts.last).to be_pending
        expect(flash[:notice]).to include("once an admin approves it")
      end
    end

    describe "history" do
      it "shows weights in the lifter's unit, rounded" do
        user.update!(weight_unit: :lb)
        log_lift(exercise: "bench", weight: "315", unit: "lb")

        get lifts_path

        expect(response.body).to include("315 lb")
        expect(response.body).not_to include("142.88")
      end

      it "filters by discipline" do
        create(:lift, user: user, exercise: :squat)
        create(:lift, user: user, exercise: :dip, weight_lifted: 0, reps: 20)

        get lifts_path(discipline: "calisthenics")

        expect(response.body).to include("Dip")
        expect(response.body).not_to include("Squat</td>")
      end
    end

    describe "editing and deleting" do
      let!(:lift) { create(:lift, user: user, exercise: :squat, weight_lifted: 100) }

      it "edits a lift" do
        get edit_lift_path(lift)
        expect(response).to have_http_status(:ok)

        patch lift_path(lift), params: { lift: { exercise: "squat", weight: "110", unit: "kg", reps: "2", bodyweight: "80" } }

        expect(response).to redirect_to(lifts_path(discipline: "powerlifting"))
        expect(lift.reload.weight_lifted).to eq(110)
        expect(lift.reps).to eq(2)
      end

      it "re-renders the edit form for invalid input" do
        patch lift_path(lift), params: { lift: { exercise: "squat", weight: "0", unit: "kg", reps: "1" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "deletes a lift" do
        expect { delete lift_path(lift) }.to change(Lift, :count).by(-1)
        expect(response).to redirect_to(lifts_path(discipline: "powerlifting"))
      end

      it "can't touch someone else's lift" do
        other_lift = create(:lift)

        get edit_lift_path(other_lift)
        expect(response).to have_http_status(:not_found)

        delete lift_path(other_lift)
        expect(response).to have_http_status(:not_found)
        expect(other_lift.reload).to be_persisted
      end
    end
  end
end
