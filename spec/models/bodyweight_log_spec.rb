require "rails_helper"

RSpec.describe BodyweightLog do
  let(:log) do
    described_class.new([
      [ Time.zone.local(2026, 3, 10, 9), 85 ],
      [ Time.zone.local(2026, 1, 10, 9), 90 ]
    ], time_zone: "Etc/UTC")
  end

  it "uses the latest weigh-in on or before the date, in any input order" do
    expect(log.on(Date.new(2026, 2, 1))).to eq(90)
    expect(log.on(Date.new(2026, 3, 10))).to eq(85)
    expect(log.on(Date.new(2026, 9, 1))).to eq(85)
  end

  it "falls back to the first weigh-in for dates before any" do
    expect(log.on(Date.new(2025, 12, 1))).to eq(90)
  end

  it "uses the latest weigh-in when there's no date" do
    expect(log.on(nil)).to eq(85)
  end

  it "is nil for an empty log" do
    expect(described_class.new([], time_zone: "Etc/UTC").on(Date.new(2026, 1, 1))).to be_nil
  end

  it "counts a weigh-in by the end of the day in the lifter's time zone" do
    # 20:00 UTC on 9 March is already 10 March in Tokyo.
    log = described_class.new([
      [ Time.utc(2026, 1, 1, 12), 90 ],
      [ Time.utc(2026, 3, 9, 20), 85 ]
    ], time_zone: "Asia/Tokyo")

    expect(log.on(Date.new(2026, 3, 9))).to eq(90)
    expect(log.on(Date.new(2026, 3, 10))).to eq(85)
  end

  it "reads a user's weigh-ins in the user's time zone" do
    user = create(:user, time_zone: "Asia/Tokyo")
    create(:bodyweight_entry, user: user, kilograms: 90, recorded_at: Time.utc(2026, 1, 1, 12))
    create(:bodyweight_entry, user: user, kilograms: 85, recorded_at: Time.utc(2026, 3, 9, 20))

    expect(described_class.for(user).on(Date.new(2026, 3, 10))).to eq(85)
    expect(user.bodyweight_on(Date.new(2026, 3, 9))).to eq(90)
  end
end
