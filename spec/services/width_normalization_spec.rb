require "rails_helper"

RSpec.describe WidthNormalization do
  describe ".normalize" do
    it "folds full-width digits and letters onto ASCII" do
      expect(described_class.normalize("１００")).to eq("100")
      expect(described_class.normalize("ｄｅｍｏ")).to eq("demo")
      expect(described_class.normalize("ｔａｒｏ＠ｅｘａｍｐｌｅ.ｃｏｍ")).to eq("taro@example.com")
    end

    it "folds half-width katakana onto normal katakana" do
      expect(described_class.normalize("ｽｸﾜｯﾄ")).to eq("スクワット")
    end

    it "leaves ordinary Japanese text alone" do
      expect(described_class.normalize("スクワット 懸垂 デッドリフト")).to eq("スクワット 懸垂 デッドリフト")
    end

    it "passes through anything that isn't a string" do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize(100)).to eq(100)
    end
  end
end
