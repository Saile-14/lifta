require "rails_helper"

RSpec.describe RefreshLeaderboardsJob do
  include ActiveJob::TestHelper

  let(:user) { create(:user, :listed) }

  before { create(:bodyweight_entry, user: user, kilograms: 80) }

  it "is enqueued when a lift is logged" do
    expect { create(:lift, user: user, exercise: :squat, weight_lifted: 150) }
      .to have_enqueued_job(described_class)
  end

  it "is enqueued when a lift is approved out of the review queue" do
    lift = create(:lift, user: user, exercise: :squat, weight_lifted: 300)
    expect(lift).to be_pending

    expect { lift.update!(status: :approved) }.to have_enqueued_job(described_class)
  end

  it "is enqueued when a lifter opts out of the leaderboard" do
    expect { user.update!(public_profile: false) }.to have_enqueued_job(described_class)
  end

  it "is not enqueued for a change that can't move a board" do
    expect { user.update!(time_zone: "Asia/Tokyo") }.not_to have_enqueued_job(described_class)
  end

  it "leaves the boards warm, so the next reader does no ranking work" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 150)
    create(:lift, user: user, exercise: :bench, weight_lifted: 100)
    create(:lift, user: user, exercise: :deadlift, weight_lifted: 180)

    perform_enqueued_jobs { described_class.perform_now }

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    entries = nil
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      entries = ComboLeaderboard.new.entries
    end

    expect(entries.sole.user).to eq(user)
    # Only the lookup of the users on the visible page.
    expect(queries).to be <= 2
  end

  it "warms every discipline board and the combined one" do
    create(:lift, user: user, exercise: :squat, weight_lifted: 150)

    described_class.perform_now

    expect(Rails.cache.exist?([ "leaderboards", LeaderboardCache.version, "powerlifting", nil, nil ])).to be(true)
    expect(Rails.cache.exist?([ "leaderboards", LeaderboardCache.version, ComboCard::KEY, nil ])).to be(true)
  end
end
