# Rebuilds the cached leaderboards after something changes them, so the
# first visitor afterwards reads a warm cache instead of paying for the
# rebuild themselves.
#
# The cache is invalidated inline at the point of change (see
# Lift#refresh_leaderboards) -- that's a single cache write, and it has to
# happen immediately so nobody is served a stale board. This job only does
# the slow part: recomputing the boards people actually land on.
class RefreshLeaderboardsJob < ApplicationJob
  queue_as :default

  # Lifts arrive in bursts -- an admin clearing the review queue approves
  # several in a row, each invalidating the cache. Only one rebuild needs to
  # run, and rebuilding while a burst is still going would just be thrown
  # away, so Solid Queue holds the rest until this one is done.
  limits_concurrency to: 1, key: "leaderboards", duration: 5.minutes

  def perform
    Discipline.all.each do |discipline|
      Leaderboard.new(discipline: discipline).entries
    end

    ComboLeaderboard.new.entries
  end
end
