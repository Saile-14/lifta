require "rails_helper"

RSpec.describe ComboLeaderboard do
  # Barbell amounts are kilograms, calisthenics amounts are reps.
  def lifter(username, sex: :male, listed: true, bodyweight: 80, **lifts)
    create(:user, username: username, sex: sex, public_profile: listed).tap do |user|
      lifts.each do |exercise, amount|
        attributes = if Discipline.for_exercise(exercise).weighted?
          { weight_lifted: amount }
        else
          { weight_lifted: 0, reps: amount }
        end
        create(:lift, user: user, exercise: exercise, bodyweight_kg: bodyweight, **attributes)
      end
    end
  end

  it "ranks on breadth, so an all-rounder beats a far stronger specialist" do
    # Platinum across powerlifting and nothing else: 80% of one discipline.
    specialist = lifter("specialist", squat: 250, bench: 170, deadlift: 280)
    # Weaker everywhere, but present in all three.
    all_rounder = lifter("all_rounder", squat: 150, bench: 100, deadlift: 180,
      snatch: 90, clean_and_jerk: 110, pull_up: 15, dip: 22, push_up: 45)

    board = described_class.new

    expect(board.entries.map(&:user)).to eq([ all_rounder, specialist ])
    expect(board.entries.map(&:position)).to eq([ 1, 2 ])
    expect(board.entries.map { |entry| entry.tier.name }).to eq([ :apex, :awakened ])
  end

  it "still shows the specialist ahead on the discipline they specialise in" do
    specialist = lifter("specialist", squat: 250, bench: 170, deadlift: 280)
    lifter("all_rounder", squat: 150, bench: 100, deadlift: 180,
      snatch: 90, clean_and_jerk: 110, pull_up: 15, dip: 22, push_up: 45)

    powerlifting = Discipline.find(:powerlifting)
    expect(Leaderboard.new(discipline: powerlifting).entries.first.user).to eq(specialist)
  end

  it "carries each discipline's contribution alongside the combined tier" do
    lifter("taro", squat: 150, bench: 100, deadlift: 180)

    entry = described_class.new.entries.sole
    expect(entry.tier).to be_a(ComboTier)
    expect(entry.card.rows.map { |row| row.discipline.key }).to eq(%w[powerlifting weightlifting calisthenics])
    expect(entry.card.rows.last.percent).to eq(0.0)
  end

  it "leaves out lifters who haven't opted in" do
    lifter("hidden", listed: false, squat: 200)

    expect(described_class.new.entries).to be_empty
  end

  it "leaves out lifters with nothing logged" do
    lifter("lurker")

    expect(described_class.new.entries).to be_empty
  end

  it "only counts approved lifts, so a lift awaiting review doesn't rank" do
    lifter("claims_a_lot", squat: 300) # diamond-level, held for review

    expect(described_class.new.entries).to be_empty
  end

  it "filters by sex while still ranking on progress toward each sex's own standard" do
    lifter("taro", squat: 150)
    hanako = lifter("hanako", sex: :female, bodyweight: 60, squat: 100)

    expect(described_class.new(sex: "female").entries.map(&:user)).to eq([ hanako ])
  end

  it "reports a lifter's position, and nothing for one who isn't on the board" do
    lifter("first", squat: 200, snatch: 100)
    second = lifter("second", squat: 100)
    absent = lifter("absent")

    board = described_class.new
    expect(board.size).to eq(2)
    expect(board.position_of(second)).to eq(2)
    expect(board.position_of(absent)).to be_nil
  end

  # ComboCard queries for its own scores unless they're handed to it, which
  # would be a query per lifter on a board of up to a hundred.
  it "loads every lifter's scores in one batch rather than one query each" do
    5.times { |n| lifter("lifter_#{n}", squat: 100 + n) }

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { described_class.new.entries }

    expect(queries).to be <= 3
  end
end
