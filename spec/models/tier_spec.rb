require "rails_helper"

RSpec.describe Tier do
  {
    0.0   => :bronze,
    39.9  => :bronze,
    40.0  => :silver,
    59.9  => :silver,
    60.0  => :gold,
    74.9  => :gold,
    75.0  => :platinum,
    89.9  => :platinum,
    90.0  => :diamond,
    99.9  => :diamond,
    100.0 => :grandmaster,
    180.0 => :grandmaster
  }.each do |percent, expected|
    it "puts #{percent}% in #{expected}" do
      expect(described_class.new(percent).name).to eq(expected)
    end
  end

  it "clamps the meter fill to 0-100 but keeps the real percentage" do
    tier = described_class.new(125.0)
    expect(tier.fill_percent).to eq(100.0)
    expect(tier.percent).to eq(125.0)
  end

  it "floors the displayed percentage so it never rounds up into the next tier" do
    expect(described_class.new(39.96).display_percent).to eq(39.9)
    expect(described_class.new(39.96).name).to eq(:bronze)
  end

  it "names the next tier up, and nothing above grandmaster" do
    expect(described_class.new(50).next_name).to eq(:gold)
    expect(described_class.new(100).next_name).to be_nil
  end

  it "flags diamond and above for review" do
    expect(described_class.new(89.9)).not_to be_needs_review
    expect(described_class.new(90.0)).to be_needs_review
  end

  it "treats more than twice the world-class standard as implausible" do
    expect(described_class.new(200.0)).not_to be_implausible
    expect(described_class.new(200.1)).to be_implausible
  end

  it "compares by percentage" do
    expect(described_class.new(41)).to be > described_class.new(40)
  end
end
