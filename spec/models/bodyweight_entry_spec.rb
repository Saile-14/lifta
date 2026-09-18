require "rails_helper"

RSpec.describe BodyweightEntry do
  subject { build(:bodyweight_entry) }

  it { is_expected.to be_valid }

  it "requires kilograms" do
    subject.kilograms = nil
    expect(subject).not_to be_valid
  end

  it "requires a positive kilograms value" do
    subject.kilograms = 0
    expect(subject).not_to be_valid

    subject.kilograms = -5
    expect(subject).not_to be_valid
  end

  it "rejects a bodyweight that can't be real" do
    subject.kilograms = 8
    expect(subject).not_to be_valid

    subject.kilograms = 800
    expect(subject).not_to be_valid
  end

  it "defaults recorded_at to now when not given" do
    entry = build(:bodyweight_entry, recorded_at: nil)
    expect { entry.valid? }.to change(entry, :recorded_at).from(nil)
  end

  it "belongs to a user" do
    subject.user = nil
    expect(subject).not_to be_valid
  end
end
