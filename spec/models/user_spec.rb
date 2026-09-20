require "rails_helper"

RSpec.describe User do
  describe "email_address normalization" do
    it "downcases and strips the email address" do
      user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
      expect(user.email_address).to eq("downcased@example.com")
    end
  end

  describe "username normalization" do
    it "downcases, strips, and drops a leading @" do
      expect(User.new(username: " @Iron_Mike ").username).to eq("iron_mike")
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
      user = User.new(email_address: "new@example.com", username: "newbie", sex: :male)
      expect(user).not_to be_valid
    end

    it "requires a unique username, ignoring case" do
      create(:user, username: "ironmike")
      subject.username = "IronMike"
      expect(subject).not_to be_valid
    end

    it "only allows 3-20 letters, numbers and underscores in a username" do
      %w[ab has-dash has.dot way_too_long_for_a_username].each do |bad|
        subject.username = bad
        expect(subject).not_to be_valid, "expected #{bad.inspect} to be rejected"
      end

      subject.username = "deadlift_dan_99"
      expect(subject).to be_valid
    end

    it "reserves usernames that could pass for staff" do
      subject.username = "admin"
      expect(subject).not_to be_valid
    end

    it "requires a real time zone" do
      subject.time_zone = "America/New_York"
      expect(subject).to be_valid

      subject.time_zone = "Mars/Olympus_Mons"
      expect(subject).not_to be_valid
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

  describe "#bodyweight_on" do
    let(:user) { create(:user) }

    before do
      create(:bodyweight_entry, user: user, kilograms: 90, recorded_at: Time.zone.local(2026, 1, 10, 9))
      create(:bodyweight_entry, user: user, kilograms: 85, recorded_at: Time.zone.local(2026, 3, 10, 9))
    end

    it "uses the latest weigh-in on or before the date" do
      expect(user.bodyweight_on(Date.new(2026, 2, 1))).to eq(90)
      expect(user.bodyweight_on(Date.new(2026, 3, 10))).to eq(85)
    end

    it "falls back to the first weigh-in for dates before any" do
      expect(user.bodyweight_on(Date.new(2025, 12, 1))).to eq(90)
    end
  end

  describe "#best_lift and #rank_for" do
    let(:user) { create(:user) }

    it "is nil for an exercise with no logged lifts" do
      expect(user.best_lift(:squat)).to be_nil
      expect(user.rank_for(:squat)).to be_nil
    end

    it "picks the highest-scoring lift for that exercise" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 100)
      stronger = create(:lift, user: user, exercise: :squat, weight_lifted: 150)
      create(:lift, user: user, exercise: :bench, weight_lifted: 200)

      expect(user.best_lift(:squat)).to eq(stronger)
      expect(user.rank_for(:squat)).to eq(stronger.tier)
    end

    it "ignores lifts that are pending review or rejected" do
      approved = create(:lift, user: user, exercise: :squat, weight_lifted: 150)
      create(:lift, user: user, exercise: :squat, weight_lifted: 300) # pending
      create(:lift, user: user, exercise: :squat, weight_lifted: 290).rejected!

      expect(user.best_lift(:squat)).to eq(approved)
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

  # Japanese keyboards type through an IME, which emits full-width forms.
  describe "input typed on a Japanese IME" do
    it "folds a full-width username to ASCII instead of rejecting it" do
      user = create(:user, username: "ｄｅｍｏ２")

      expect(user.username).to eq("demo2")
      expect(user).to be_valid
    end

    it "folds a full-width email address, and still authenticates either way" do
      create(:user, email_address: "ｔａｒｏ＠ｅｘａｍｐｌｅ.ｃｏｍ", password: "password123")

      expect(described_class.authenticate_by(email_address: "taro@example.com", password: "password123")).to be_present
      expect(described_class.authenticate_by(email_address: "ｔａｒｏ＠ｅｘａｍｐｌｅ.ｃｏｍ", password: "password123")).to be_present
    end
  end
end
