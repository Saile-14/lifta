# Leaderboards are identical for everyone who asks and expensive to build:
# ranking costs time proportional to the whole user base, to render one page
# of a hundred. Measured on seeded data, the combined board took ~2.1s at
# 20,000 lifters, roughly two thirds of it in Ruby rather than SQL.
#
# So the ranking is cached in Solid Cache. What's stored is plain data --
# [user_id, percent, ...] tuples, not Active Record objects -- because the
# cache outlives the request and cached models go stale in ways that are
# hard to see. The visible hundred users are loaded fresh on every read.
#
# Invalidation is by version, not by deleting keys. There's one entry per
# discipline x exercise x sex filter, and no cache store deletes reliably by
# prefix; bumping the version orphans every entry at once and they age out
# on their own.
module LeaderboardCache
  VERSION_KEY = "leaderboards/version"

  # A cached board is only reachable while the version matches, so this is a
  # backstop against orphaned entries sitting in the cache, not the real
  # expiry.
  TTL = 12.hours

  module_function

  def fetch(key, &)
    Rails.cache.fetch([ "leaderboards", version, *key ], expires_in: TTL, &)
  end

  def version
    Rails.cache.fetch(VERSION_KEY) { new_version }
  end

  # Called whenever an approved lift or a listed lifter changes. A cache
  # write, so it's cheap enough to do inline in an after_commit.
  def invalidate!
    Rails.cache.write(VERSION_KEY, new_version, expires_in: TTL)
  end

  def new_version
    Time.current.to_f.to_s
  end
end
