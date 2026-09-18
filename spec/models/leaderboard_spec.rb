require "rails_helper"

RSpec.describe Leaderboard do
  let(:powerlifting) { Discipline.find(:powerlifting) }
  let(:squat) { powerlifting.exercise(:squat) }

  def lifter(username, sex: :male, listed: true, bodyweight: 80, **lifts)
    create(:user, username: username, sex: sex, public_profile: listed).tap do |user|
      lifts.each do |exercise, kg|
        create(:lift, user: user, exercise: exercise, weight_lifted: kg, bodyweight_kg: bodyweight)
      end
    end
  end

  it "ranks listed lifters on one exercise, best first, with the lift behind each rank" do
    weaker = lifter("weaker", squat: 150)
    stronger = lifter("stronger", squat: 200)

    board = described_class.new(discipline: powerlifting, exercise: squat)

    expect(board.entries.map(&:user)).to eq([ stronger, weaker ])
    expect(board.entries.map(&:position)).to eq([ 1, 2 ])
    expect(board.entries.first.lift.weight_lifted).to eq(200)
    expect(board.entries.first.tier.name).to eq(:gold)
  end

  it "leaves out lifters who haven't opted in" do
    lifter("private", listed: false, squat: 200)

    expect(described_class.new(discipline: powerlifting, exercise: squat).entries).to be_empty
  end

  it "only counts approved lifts" do
    user = lifter("claims_a_lot", squat: 150)
    create(:lift, user: user, exercise: :squat, weight_lifted: 300) # waiting for review

    entry = described_class.new(discipline: powerlifting, exercise: squat).entries.sole
    expect(entry.lift.weight_lifted).to eq(150)
  end

  it "needs every lift for the overall board, and ranks on the DOTS total" do
    complete = lifter("complete", squat: 150, bench: 100, deadlift: 180)
    lifter("squat_only", squat: 250)

    entry = described_class.new(discipline: powerlifting).entries.sole

    expect(entry.user).to eq(complete)
    expect(entry.score).to eq(complete.lifts.sum(:score))
  end

  it "puts men and women on one board by their progress toward their own standard" do
    man = lifter("man", squat: 150) # ~48% of the men's squat standard
    woman = lifter("woman", sex: :female, bodyweight: 60, squat: 120) # ~63% of the women's

    board = described_class.new(discipline: powerlifting, exercise: squat)
    expect(board.entries.map(&:user)).to eq([ woman, man ])

    women_only = described_class.new(discipline: powerlifting, exercise: squat, sex: "female")
    expect(women_only.entries.map(&:user)).to eq([ woman ])
  end

  it "knows where a lifter stands" do
    lifter("first", squat: 200)
    second = lifter("second", squat: 150)
    unranked = lifter("unranked")

    board = described_class.new(discipline: powerlifting, exercise: squat)
    expect(board.position_of(second)).to eq(2)
    expect(board.position_of(unranked)).to be_nil
    expect(board.size).to eq(2)
  end
end
