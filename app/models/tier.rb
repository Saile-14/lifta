# A place on the bronze -> grandmaster ladder, from how far a score is toward
# the world-class standard for its lift (see Scale).
class Tier
  include Comparable

  # Minimum percentage for each tier, lowest first.
  LADDER = { bronze: 0, silver: 40, gold: 60, platinum: 75, diamond: 90, grandmaster: 100 }.freeze
  NAMES = LADDER.keys.freeze

  # Lifts at or above this tier wait for an admin to approve them.
  REVIEW_FROM = :diamond

  # Beyond this a lift is almost certainly a typo or a kg/lb mix-up, not a
  # new world record.
  IMPLAUSIBLE_ABOVE = 200.0

  attr_reader :percent

  def initialize(percent)
    @percent = percent.to_f
  end

  def name
    NAMES.reverse.find { |tier| percent >= LADDER[tier] } || :bronze
  end

  def label
    name.to_s.capitalize
  end

  def level
    NAMES.index(name)
  end

  def next_name
    NAMES[level + 1]
  end

  # Width of the rank meter.
  def fill_percent
    percent.clamp(0.0, 100.0)
  end

  # Floored, so 39.96% reads 39.9% (bronze) rather than rounding up to a
  # silver-looking 40.0%.
  def display_percent
    (percent * 10).floor / 10.0
  end

  def needs_review?
    percent >= LADDER.fetch(REVIEW_FROM)
  end

  def implausible?
    percent > IMPLAUSIBLE_ABOVE
  end

  def <=>(other)
    percent <=> other.percent
  end

  def to_s
    "#{label} (#{display_percent}%)"
  end
end
