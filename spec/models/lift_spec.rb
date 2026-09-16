require "rails_helper"

RSpec.describe Lift do
  let(:user) { create(:user) }

  before { create(:bodyweight_entry, user: user, kilograms: 80) }

  subject { build(:lift, user: user) }

  it { is_expected.to be_valid }

  describe "validations" do
    it "requires an exercise" do
      subject.exercise = nil
      expect(subject).not_to be_valid
    end

    it "requires a positive weight_lifted" do
      subject.weight_lifted = 0
      expect(subject).not_to be_valid
    end

    it "requires a positive integer reps" do
      subject.reps = 0
      expect(subject).not_to be_valid

      subject.reps = 1.5
      expect(subject).not_to be_valid
    end
  end

  describe "exercise enum" do
    it "supports squat, bench, and deadlift" do
      expect(described_class.exercises).to eq("squat" => 0, "bench" => 1, "deadlift" => 2)
    end
  end

  describe "bodyweight_kg snapshot" do
    it "defaults to the user's current bodyweight when not given" do
      lift = build(:lift, user: user, bodyweight_kg: nil)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(80)
    end

    it "keeps an explicitly given bodyweight_kg instead of the user's current bodyweight" do
      lift = build(:lift, user: user, bodyweight_kg: 82.4)
      lift.valid?
      expect(lift.bodyweight_kg).to eq(82.4)
    end

    it "is invalid when the user has no bodyweight logged and none is given" do
      bodyweightless_user = create(:user)
      lift = build(:lift, user: bodyweightless_user, bodyweight_kg: nil)
      expect(lift).not_to be_valid
      expect(lift.errors[:bodyweight_kg]).to be_present
    end
  end

  describe "lifted_at default" do
    it "defaults to today when not given" do
      lift = build(:lift, user: user, lifted_at: nil)
      lift.valid?
      expect(lift.lifted_at).to eq(Date.current)
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
  end

  describe "#benchmark" do
    it "scores a multi-rep set at least as high as an equivalent single rep, via the estimated 1RM" do
      single = build(:lift, user: user, weight_lifted: 100, reps: 1, bodyweight_kg: 80)
      multi = build(:lift, user: user, weight_lifted: 100, reps: 5, bodyweight_kg: 80)

      expect(multi.benchmark.fill_percent).to be > single.benchmark.fill_percent
    end

    it "returns a Dots::Tier" do
      expect(subject.benchmark).to be_a(Dots::Tier)
    end
  end
end
