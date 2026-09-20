require "rails_helper"

RSpec.describe ComboCard do
  let(:user) { create(:user) }

  before { create(:bodyweight_entry, user: user, kilograms: 80) }

  subject(:card) { described_class.new(user) }

  # A full world-class powerlifting total and nothing else.
  def complete_powerlifting!
    create(:lift, user: user, exercise: :squat, weight_lifted: 150)
    create(:lift, user: user, exercise: :bench, weight_lifted: 100)
    create(:lift, user: user, exercise: :deadlift, weight_lifted: 180)
  end

  it "has a row per discipline, in the usual order" do
    expect(card.rows.map { |row| row.discipline.key }).to eq(%w[powerlifting weightlifting calisthenics])
  end

  it "is unranked until something is logged" do
    expect(card).not_to be_ranked
    expect(card.percent).to eq(0.0)
    expect(card.tier.name).to eq(:dormant)
  end

  it "counts an untrained discipline as zero, so the average is a third of one discipline" do
    complete_powerlifting!

    powerlifting = card.row_for(Discipline.find(:powerlifting))
    expect(card).to be_ranked
    expect(card.percent).to be_within(0.001).of(powerlifting.percent / 3)
  end

  it "gives partial credit inside a discipline that isn't finished yet" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 150)

    powerlifting = card.row_for(Discipline.find(:powerlifting))
    expect(powerlifting.percent).to be > 0
    expect(powerlifting).not_to be_ranked, "the discipline's own tier waits for every exercise"
    expect(powerlifting.tier).to be_nil
  end

  it "carries the discipline's own tier once every exercise in it has a lift" do
    complete_powerlifting!

    powerlifting = card.row_for(Discipline.find(:powerlifting))
    expect(powerlifting).to be_ranked
    expect(powerlifting.tier.percent).to be_within(0.001).of(powerlifting.percent)
  end

  it "reaches the top rung only on world-class strength in all three at once" do
    Discipline.all.each { |discipline| allow(discipline).to receive(:progress_percent).and_return(95.0) }
    expect(card.tier.name).to eq(:ultimate_lifeform)

    allow(Discipline.find(:calisthenics)).to receive(:progress_percent).and_return(0.0)
    expect(described_class.new(user).tier.name).to eq(:apex), "two out of three isn't enough"
  end

  it "ignores lifts waiting for review" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 300)

    expect(card).not_to be_ranked
    expect(card.percent).to eq(0.0)
  end

  it "takes injected scores instead of querying, so a leaderboard can batch them" do
    scores = { "squat" => 200.0 }
    expect(user).not_to receive(:lifts)

    expect(described_class.new(user, scores: scores)).to be_ranked
  end
end
