require "rails_helper"

RSpec.describe ComboTier do
  {
    0.0   => :dormant,
    14.9  => :dormant,
    15.0  => :awakened,
    29.9  => :awakened,
    30.0  => :evolved,
    49.9  => :evolved,
    50.0  => :apex,
    69.9  => :apex,
    70.0  => :transcendent,
    89.9  => :transcendent,
    90.0  => :ultimate_lifeform,
    140.0 => :ultimate_lifeform
  }.each do |percent, expected|
    it "puts #{percent}% in #{expected}" do
      expect(described_class.new(percent).name).to eq(expected)
    end
  end

  it "labels rungs from its own scope, not the per-lift tier scope" do
    expect(described_class.new(95.0).label).to eq(I18n.t("combo_tiers.ultimate_lifeform"))
    expect(described_class.new(0.0).label).to eq(I18n.t("combo_tiers.dormant"))
  end

  it "has no rung above the top one" do
    expect(described_class.new(95.0).next_name).to be_nil
    expect(described_class.new(0.0).next_name).to eq(:awakened)
  end

  it "shares the meter and ordering behaviour of the per-lift ladder" do
    expect(described_class.new(125.0).fill_percent).to eq(100.0)
    expect(described_class.new(29.96).display_percent).to eq(29.9)
    expect(described_class.new(10.0)).to be < described_class.new(80.0)
  end
end
