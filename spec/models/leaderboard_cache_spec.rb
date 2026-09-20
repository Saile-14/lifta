require "rails_helper"

RSpec.describe LeaderboardCache do
  let(:powerlifting) { Discipline.find(:powerlifting) }

  def lifter(username, **lifts)
    create(:user, username: username, public_profile: true).tap do |user|
      lifts.each { |exercise, kg| create(:lift, user: user, exercise: exercise, weight_lifted: kg, bodyweight_kg: 80) }
    end
  end

  # Counting queries is the point: a cached board should do the cheap work
  # (loading the hundred users it shows) and skip the expensive ranking.
  def queries_for
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  it "builds the ranking once and reuses it" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)

    first = queries_for { Leaderboard.new(discipline: powerlifting).entries }
    second = queries_for { Leaderboard.new(discipline: powerlifting).entries }

    expect(second).to be < first
  end

  it "serves the same entries from a warm cache" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)
    lifter("hanako", squat: 120, bench: 80, deadlift: 150)

    cold = Leaderboard.new(discipline: powerlifting).entries.map { |e| [ e.user.username, e.position ] }
    warm = Leaderboard.new(discipline: powerlifting).entries.map { |e| [ e.user.username, e.position ] }

    expect(warm).to eq(cold)
  end

  it "drops the cached ranking when a lift changes it" do
    taro = lifter("taro", squat: 150, bench: 100, deadlift: 180)

    before = Leaderboard.new(discipline: powerlifting).entries.sole.tier.percent

    create(:lift, user: taro, exercise: :squat, weight_lifted: 260, bodyweight_kg: 80)

    expect(Leaderboard.new(discipline: powerlifting).entries.sole.tier.percent).to be > before
  end

  it "drops it when a new lifter overtakes the board" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)
    expect(Leaderboard.new(discipline: powerlifting).entries.first.user.username).to eq("taro")

    lifter("hanako", squat: 200, bench: 140, deadlift: 240)

    expect(Leaderboard.new(discipline: powerlifting).entries.first.user.username).to eq("hanako")
  end

  it "drops it when a lifter opts out of being listed" do
    taro = lifter("taro", squat: 150, bench: 100, deadlift: 180)

    expect(Leaderboard.new(discipline: powerlifting).size).to eq(1)

    taro.update!(public_profile: false)

    expect(Leaderboard.new(discipline: powerlifting).size).to eq(0)
  end

  it "shows a renamed lifter under the new name without rebuilding the ranking" do
    taro = lifter("taro", squat: 150, bench: 100, deadlift: 180)
    Leaderboard.new(discipline: powerlifting).entries

    taro.update_column(:username, "taro_new") # no callbacks, so the cache stands

    expect(Leaderboard.new(discipline: powerlifting).entries.first.user.username).to eq("taro_new")
  end

  it "keeps each filter in its own entry" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)
    create(:user, username: "hanako", sex: :female, public_profile: true).tap do |user|
      { squat: 120, bench: 70, deadlift: 140 }.each do |exercise, kg|
        create(:lift, user: user, exercise: exercise, weight_lifted: kg, bodyweight_kg: 60)
      end
    end

    everyone = Leaderboard.new(discipline: powerlifting).size
    women = Leaderboard.new(discipline: powerlifting, sex: "female").size

    expect(everyone).to eq(2)
    expect(women).to eq(1)
  end

  it "caches the combined board separately from the discipline boards" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)

    expect(ComboLeaderboard.new.entries.sole.user.username).to eq("taro")
    expect(Leaderboard.new(discipline: powerlifting).entries.sole.user.username).to eq("taro")
  end

  describe ".invalidate!" do
    it "changes the version, so previously cached boards are unreachable" do
      before = described_class.version
      described_class.invalidate!

      expect(described_class.version).not_to eq(before)
    end
  end
end
