require "rails_helper"

RSpec.describe WeightConversion do
  describe ".to_kg" do
    it "returns the amount unchanged for kg" do
      expect(described_class.to_kg(80, "kg")).to eq(80.0)
    end

    it "converts pounds to kilograms" do
      expect(described_class.to_kg(220.462, "lb")).to be_within(0.01).of(100.0)
    end
  end

  describe ".from_kg" do
    it "returns the amount unchanged for kg" do
      expect(described_class.from_kg(80, "kg")).to eq(80.0)
    end

    it "converts kilograms to pounds" do
      expect(described_class.from_kg(100, "lb")).to be_within(0.01).of(220.46)
    end
  end

  it "round-trips within a small tolerance" do
    expect(described_class.from_kg(described_class.to_kg(185, "lb"), "lb")).to be_within(0.001).of(185)
  end
end
