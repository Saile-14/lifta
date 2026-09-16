require "rails_helper"

RSpec.describe User do
  describe "email_address normalization" do
    it "downcases and strips the email address" do
      user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
      expect(user.email_address).to eq("downcased@example.com")
    end
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to be_valid }

    it "requires an email_address" do
      subject.email_address = nil
      expect(subject).not_to be_valid
    end

    it "requires a unique email_address" do
      create(:user, email_address: "taken@example.com")
      subject.email_address = "taken@example.com"
      expect(subject).not_to be_valid
    end

    it "requires a sex" do
      subject.sex = nil
      expect(subject).not_to be_valid
    end

    it "requires a password" do
      user = User.new(email_address: "new@example.com", sex: :male)
      expect(user).not_to be_valid
    end
  end

  describe "enums" do
    it "exposes sex as male/female" do
      expect(described_class.sexes).to eq("male" => 0, "female" => 1)
    end

    it "exposes weight_unit as kg/lb, defaulting to kg" do
      expect(described_class.weight_units).to eq("kg" => 0, "lb" => 1)
      expect(build(:user).weight_unit).to eq("kg")
    end
  end

  describe "#current_bodyweight_kg" do
    let(:user) { create(:user) }

    it "is nil when no bodyweight has been logged" do
      expect(user.current_bodyweight_kg).to be_nil
    end

    it "returns the most recently recorded bodyweight" do
      create(:bodyweight_entry, user: user, kilograms: 80, recorded_at: 2.days.ago)
      newest = create(:bodyweight_entry, user: user, kilograms: 78.5, recorded_at: 1.day.ago)

      expect(user.current_bodyweight_kg).to eq(newest.kilograms)
    end
  end

  describe "#best_lift and #rank_for" do
    let(:user) { create(:user) }

    before { create(:bodyweight_entry, user: user, kilograms: 80) }

    it "is nil for an exercise with no logged lifts" do
      expect(user.best_lift(:squat)).to be_nil
      expect(user.rank_for(:squat)).to be_nil
    end

    it "picks the lift with the highest DOTS score for that exercise" do
      weaker = create(:lift, user: user, exercise: :squat, weight_lifted: 100, bodyweight_kg: 80)
      stronger = create(:lift, user: user, exercise: :squat, weight_lifted: 150, bodyweight_kg: 80)
      create(:lift, user: user, exercise: :bench, weight_lifted: 200, bodyweight_kg: 80)

      expect(user.best_lift(:squat)).to eq(stronger)
      expect(user.rank_for(:squat)).to eq(stronger.benchmark)
    end
  end

  describe "associations" do
    it "destroys dependent sessions, bodyweight_entries, and lifts" do
      %i[sessions bodyweight_entries lifts].each do |name|
        reflection = described_class.reflect_on_association(name)
        expect(reflection.macro).to eq(:has_many)
        expect(reflection.options[:dependent]).to eq(:destroy)
      end
    end
  end
end
