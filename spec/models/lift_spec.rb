require "rails_helper"

RSpec.describe Lift do
  let(:user) { create(:user) }

  subject { build(:lift, user: user) }

  it { is_expected.to be_valid }

  describe "validations" do
    it "requires an exercise" do
      subject.exercise = nil
      expect(subject).not_to be_valid
    end

    it "requires a positive weight for barbell lifts" do
      subject.weight_lifted = 0
      expect(subject).not_to be_valid

      subject.weight_lifted = nil
      expect(subject).not_to be_valid
    end

    it "allows no added weight for calisthenics, but not negative weight" do
      lift = build(:lift, user: user, exercise: :pull_up, weight_lifted: nil, reps: 10)
      expect(lift).to be_valid
      expect(lift.weight_lifted).to eq(0)

      lift.weight_lifted = -5
      expect(lift).not_to be_valid
    end

    it "requires a positive integer reps" do
      subject.reps = 0
      expect(subject).not_to be_valid

      subject.reps = 1.5
      expect(subject).not_to be_valid
    end

    it "caps powerlifting sets at 10 reps, since longer sets don't estimate a max reliably" do
      subject.reps = 10
      expect(subject).to be_valid

      subject.reps = 11
      expect(subject).not_to be_valid
      expect(subject.errors[:reps].first).to include("can't be more than 10")
    end

    it "caps weightlifting sets at 3 reps" do
      lift = build(:lift, user: user, exercise: :snatch, weight_lifted: 60, reps: 4)
      expect(lift).not_to be_valid
    end

    it "rejects a bodyweight that can't be real" do
      subject.bodyweight_kg = 8
      expect(subject).not_to be_valid

      subject.bodyweight_kg = 800
      expect(subject).not_to be_valid
    end

    it "rejects lifts far beyond the world record, like typos and kg/lb mix-ups" do
      lift = build(:lift, user: user, exercise: :deadlift, weight_lifted: 1600, bodyweight_kg: 80)
      expect(lift).not_to be_valid
      expect(lift.errors[:base].first).to include("far beyond the world record")
    end
  end

  describe "exercise enum" do
    it "covers every discipline's exercises" do
      expect(described_class.exercises.keys).to eq(Discipline.exercise_keys)
    end
  end

  describe "bodyweight_kg snapshot" do
    before do
      create(:bodyweight_entry, user: user, kilograms: 90, recorded_at: 100.days.ago)
      create(:bodyweight_entry, user: user, kilograms: 80, recorded_at: 1.day.ago)
    end

    it "defaults to the user's latest bodyweight for a lift today" do
      lift = build(:lift, user: user, bodyweight_kg: nil, lifted_at: nil)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(80)
    end

    it "uses the bodyweight logged as of a backdated lift's date, not today's" do
      lift = build(:lift, user: user, bodyweight_kg: nil, lifted_at: 50.days.ago.to_date)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(90)
    end

    it "falls back to the earliest bodyweight for lifts before the first weigh-in" do
      lift = build(:lift, user: user, bodyweight_kg: nil, lifted_at: 200.days.ago.to_date)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(90)
    end

    it "keeps an explicitly given bodyweight_kg" do
      lift = build(:lift, user: user, bodyweight_kg: 82.4)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(82.4)
    end

    it "explains that bodyweight is needed when there's none to use" do
      lift = build(:lift, user: create(:user), bodyweight_kg: nil)
      expect(lift).not_to be_valid
      expect(lift.errors.full_messages).to eq([ "Bodyweight is needed to score this lift" ])
    end

    it "doesn't need a bodyweight for plain calisthenics reps" do
      lift = build(:lift, user: create(:user), exercise: :push_up, weight_lifted: 0, reps: 30, bodyweight_kg: nil)
      expect(lift).to be_valid
      expect(lift.score).to eq(30)
    end
  end

  describe "lifted_at default" do
    it "defaults to today in the lifter's time zone" do
      user.update!(time_zone: "America/New_York")

      travel_to Time.utc(2026, 9, 18, 2, 0) do # 10pm on the 17th in New York
        lift = build(:lift, user: user, lifted_at: nil)
        lift.valid?
        expect(lift.lifted_at).to eq(Date.new(2026, 9, 17))
      end
    end
  end

  describe "score" do
    it "stores DOTS points for powerlifting" do
      lift = create(:lift, user: user, exercise: :squat, weight_lifted: 200, reps: 1, bodyweight_kg: 80)
      expect(lift.score).to eq(137.91)
    end

    it "stores Sinclair points for weightlifting" do
      lift = create(:lift, user: user, exercise: :snatch, weight_lifted: 100, reps: 1, bodyweight_kg: 81)
      expect(lift.score).to eq(Sinclair::Calculator.new(weight_lifted: 100, bodyweight: 81, sex: :male).call)
    end

    it "stores bodyweight-equivalent reps for calisthenics" do
      lift = create(:lift, user: user, exercise: :pull_up, weight_lifted: 20, reps: 8, bodyweight_kg: 80)
      expect(lift.score).to eq(17.5)
    end

    it "rescores when the lift is edited" do
      lift = create(:lift, user: user, weight_lifted: 100)
      expect { lift.update!(weight_lifted: 120) }.to change { lift.reload.score }
    end
  end

  describe "review status" do
    it "approves lifts below diamond straight away" do
      expect(create(:lift, user: user, weight_lifted: 200)).to be_approved
    end

    it "holds diamond-and-above lifts for review" do
      lift = create(:lift, user: user, exercise: :squat, weight_lifted: 300, bodyweight_kg: 80)
      expect(lift.tier.name).to eq(:diamond)
      expect(lift).to be_pending
    end

    it "re-reviews an approved lift when its numbers change" do
      lift = create(:lift, user: user, weight_lifted: 200)
      lift.update!(weight_lifted: 300)
      expect(lift).to be_pending
    end

    it "keeps an admin's approval when only the date changes" do
      lift = create(:lift, user: user, weight_lifted: 300)
      lift.update!(status: :approved)
      lift.update!(lifted_at: 1.day.ago.to_date)
      expect(lift.reload).to be_approved
    end

    it "releases a held lift once it's edited below diamond" do
      lift = create(:lift, user: user, weight_lifted: 300)
      lift.update!(weight_lifted: 200)
      expect(lift).to be_approved
    end
  end

  describe "#tier" do
    it "ranks the lift on its discipline's scale" do
      lift = build(:lift, user: user, exercise: :deadlift, weight_lifted: 160, bodyweight_kg: 80)
      lift.valid?
      expect(lift.tier.name).to eq(:silver)
    end
  end

  describe "#estimated_one_rep_max" do
    it "returns weight_lifted directly for a single rep" do
      lift = build(:lift, user: user, weight_lifted: 100, reps: 1)
      expect(lift.estimated_one_rep_max).to eq(100)
    end

    it "applies the Epley formula for multi-rep sets" do
      lift = build(:lift, user: user, weight_lifted: 100, reps: 5)
      expect(lift.estimated_one_rep_max).to eq(100 * (1 + 5 / 30.0))
    end

    it "is nil for calisthenics" do
      expect(build(:lift, user: user, exercise: :dip, weight_lifted: 0, reps: 10).estimated_one_rep_max).to be_nil
    end
  end

  describe "#rescore!" do
    it "recomputes a stale score and re-reviews the lift" do
      lift = create(:lift, user: user, weight_lifted: 300)
      lift.update_columns(score: 1, status: "approved")

      lift.rescore!

      expect(lift.reload.score).to eq(Dots::Calculator.new(weight_lifted: 300, bodyweight: 80, sex: :male).call)
      expect(lift).to be_pending
    end
  end
end
