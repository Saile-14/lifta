require "rails_helper"

RSpec.describe Scale do
  describe ".linear" do
    subject(:scale) { described_class.linear(200) }

    it "is the score as a share of the ceiling, past 100% too" do
      expect(scale.percent_for(0)).to eq(0.0)
      expect(scale.percent_for(100)).to eq(50.0)
      expect(scale.percent_for(200)).to eq(100.0)
      expect(scale.percent_for(250)).to eq(125.0)
    end

    it "puts each tier's threshold at its ladder percentage of the ceiling" do
      expect(scale.threshold(:bronze)).to eq(0.0)
      expect(scale.threshold(:silver)).to eq(80.0)
      expect(scale.threshold(:diamond)).to eq(180.0)
      expect(scale.ceiling).to eq(200.0)
    end
  end

  describe "with explicit thresholds" do
    subject(:scale) { described_class.new(silver: 8, gold: 15, platinum: 22, diamond: 30, grandmaster: 40) }

    it "interpolates within each tier" do
      expect(scale.percent_for(4)).to eq(20.0)
      expect(scale.percent_for(8)).to eq(40.0)
      expect(scale.percent_for(11.5)).to eq(50.0)
      expect(scale.percent_for(40)).to eq(100.0)
    end

    it "keeps scaling past grandmaster" do
      expect(scale.percent_for(60)).to eq(150.0)
    end

    it "reaches a tier exactly at its threshold" do
      expect(scale.tier_for(14.9).name).to eq(:silver)
      expect(scale.tier_for(15).name).to eq(:gold)
    end
  end
end
