# A place on the bronze -> grandmaster ladder, from how far a score is toward
# the world-class standard for its lift (see Scale).
class Tier
  include RankLadder

  # Minimum percentage for each tier, lowest first.
  LADDER = { bronze: 0, silver: 40, gold: 60, platinum: 75, diamond: 90, grandmaster: 100 }.freeze
  NAMES = LADDER.keys.freeze

  I18N_SCOPE = "tiers"

  # Lifts at or above this tier wait for an admin to approve them.
  REVIEW_FROM = :diamond

  # Beyond this a lift is almost certainly a typo or a kg/lb mix-up, not a
  # new world record.
  IMPLAUSIBLE_ABOVE = 200.0

  def needs_review?
    percent >= LADDER.fetch(REVIEW_FROM)
  end

  def implausible?
    percent > IMPLAUSIBLE_ABOVE
  end
end
