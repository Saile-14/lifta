require "rails_helper"

RSpec.describe Dots::Calculator do
  # Expected values independently derived from the published DOTS
  # polynomial (not the implementation) for these weight/bodyweight/sex
  # combinations.
  it "scores a 200kg lift at 80kg bodyweight for a male lifter" do
    score = described_class.new(weight_lifted: 200, bodyweight: 80, sex: :male).call
    expect(score).to eq(137.91)
  end

  it "scores a 120kg lift at 60kg bodyweight for a female lifter" do
    score = described_class.new(weight_lifted: 120, bodyweight: 60, sex: :female).call
    expect(score).to eq(133.03)
  end

  it "scores a 600kg lift at 100kg bodyweight for a male lifter" do
    score = described_class.new(weight_lifted: 600, bodyweight: 100, sex: :male).call
    expect(score).to eq(369.31)
  end

  it "accepts sex as a string" do
    score = described_class.new(weight_lifted: 200, bodyweight: 80, sex: "male").call
    expect(score).to eq(137.91)
  end

  it "raises for an unsupported sex" do
    expect {
      described_class.new(weight_lifted: 200, bodyweight: 80, sex: :other).call
    }.to raise_error(ArgumentError, /unsupported sex/)
  end

  describe ".coefficient" do
    it "is the multiplier from kilograms to DOTS points" do
      expect(200 * described_class.coefficient(bodyweight: 80, sex: :male)).to be_within(0.005).of(137.91)
    end

    it "clamps bodyweight to the published 40-210kg range for men" do
      expect(described_class.coefficient(bodyweight: 250, sex: :male))
        .to eq(described_class.coefficient(bodyweight: 210, sex: :male))
      expect(described_class.coefficient(bodyweight: 30, sex: :male))
        .to eq(described_class.coefficient(bodyweight: 40, sex: :male))
    end

    it "clamps bodyweight to the published 40-150kg range for women" do
      expect(described_class.coefficient(bodyweight: 180, sex: :female))
        .to eq(described_class.coefficient(bodyweight: 150, sex: :female))
      expect(described_class.coefficient(bodyweight: 30, sex: :female))
        .to eq(described_class.coefficient(bodyweight: 40, sex: :female))
    end
  end
end
