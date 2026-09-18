require "rails_helper"

RSpec.describe Sinclair::Calculator do
  # Expected values independently derived from the IWF formula,
  # 10^(A * log10(bodyweight / b)^2), with the 2021-2024 constants.
  it "scores a 378kg total at 81kg bodyweight for a male lifter" do
    expect(described_class.new(weight_lifted: 378, bodyweight: 81, sex: :male).call).to eq(479.74)
  end

  it "scores a 247kg total at 59kg bodyweight for a female lifter" do
    expect(described_class.new(weight_lifted: 247, bodyweight: 59, sex: :female).call).to eq(337.97)
  end

  it "doesn't adjust lifters at or above the reference bodyweight" do
    expect(described_class.coefficient(bodyweight: 200, sex: :male)).to eq(1.0)
    expect(described_class.new(weight_lifted: 300, bodyweight: 200, sex: :male).call).to eq(300.0)
  end

  it "accepts sex as a string" do
    expect(described_class.new(weight_lifted: 378, bodyweight: 81, sex: "male").call).to eq(479.74)
  end

  it "raises for an unsupported sex" do
    expect {
      described_class.new(weight_lifted: 100, bodyweight: 80, sex: :other).call
    }.to raise_error(ArgumentError, /unsupported sex/)
  end
end
