require "rails_helper"

RSpec.describe Dots::Tier do
  # World record DOTS is 600, so score = desired_percent * 6.0
  {
    0.0    => :bronze,
    40.0   => :bronze,
    40.1   => :silver,
    60.0   => :silver,
    60.1   => :gold,
    75.0   => :gold,
    75.1   => :platinum,
    90.0   => :platinum,
    90.1   => :diamond,
    99.9   => :diamond,
    100.0  => :grandmaster
  }.each do |percent, expected_tier|
    it "maps #{percent}% of world record DOTS to #{expected_tier}" do
      tier = described_class.for(score: percent * 6.0)
      expect(tier.name).to eq(expected_tier)
    end
  end

  it "clamps fill_percent at 100 for scores above the world record" do
    tier = described_class.for(score: 900)
    expect(tier.name).to eq(:grandmaster)
    expect(tier.fill_percent).to eq(100.0)
  end

  it "rounds fill_percent to one decimal place" do
    tier = described_class.for(score: 123.456)
    expect(tier.fill_percent).to eq((123.456 / 600.0 * 100).round(1))
  end
end
