require "rails_helper"

RSpec.describe RankCard do
  let(:user) { create(:user) }
  let(:powerlifting) { Discipline.find(:powerlifting) }

  before { create(:bodyweight_entry, user: user, kilograms: 80) }

  subject(:card) { described_class.new(user, powerlifting) }

  it "has a row per exercise with the best approved lift and its tier" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 100)
    best = create(:lift, user: user, exercise: :squat, weight_lifted: 150)

    squat = card.rows.first
    expect(card.rows.map { |row| row.exercise.key }).to eq(%w[squat bench deadlift])
    expect(squat.lift).to eq(best)
    expect(squat.tier).to eq(best.tier)
    expect(card.rows.second.lift).to be_nil
  end

  it "has no overall rank until every exercise has a lift" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 150)
    create(:lift, user: user, exercise: :bench, weight_lifted: 100)

    expect(card).to be_ranked
    expect(card).not_to be_complete
    expect(card.overall).to be_nil
    expect(card.total_score).to be_nil
  end

  it "ranks the total once every exercise has a lift" do
    lifts = [ create(:lift, user: user, exercise: :squat, weight_lifted: 150),
              create(:lift, user: user, exercise: :bench, weight_lifted: 100),
              create(:lift, user: user, exercise: :deadlift, weight_lifted: 180) ]
    total = lifts.sum(&:score)

    expect(card.total_score).to eq(total)
    expect(card.overall.percent).to be_within(0.001).of(100.0 * total / 600)
  end

  it "doesn't count lifts waiting for review" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 300)
    expect(card.rows.first.lift).to be_nil
  end

  it "gives next-tier targets at the lifter's current bodyweight, in their unit" do
    user.update!(weight_unit: :lb)
    create(:lift, user: user, exercise: :squat, weight_lifted: 120, reps: 3)

    target = card.rows.first.target
    expect(target.tier_name).to eq(:gold)
    expect(WeightConversion.from_kg(target.weight_kg, "lb")).to be_within(0.001).of(415)
  end
end
