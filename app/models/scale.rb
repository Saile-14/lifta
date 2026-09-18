# Maps a score onto the tier ladder. Every tier above bronze has a threshold
# score; the percentage interpolates linearly between thresholds (bronze
# starts at 0) and keeps scaling past grandmaster.
class Scale
  # The usual case: tiers sit at their ladder percentage of one world-class
  # ceiling, so the percentage is simply score / ceiling.
  def self.linear(ceiling)
    new(Tier::LADDER.except(:bronze).transform_values { |percent| ceiling * percent / 100.0 })
  end

  attr_reader :thresholds

  def initialize(thresholds)
    @thresholds = thresholds.to_h { |tier, score| [ tier.to_sym, score.to_f ] }
    @points = [ [ 0.0, 0.0 ] ] + @thresholds.map { |tier, score| [ score, Tier::LADDER.fetch(tier).to_f ] }
  end

  def tier_for(score)
    Tier.new(percent_for(score))
  end

  def percent_for(score)
    score = score.to_f
    top_score, top_percent = @points.last
    return top_percent * score / top_score if score >= top_score

    (low_score, low_percent), (high_score, high_percent) = @points.each_cons(2).find { |_, (high, _)| score < high }
    low_percent + (high_percent - low_percent) * (score - low_score) / (high_score - low_score)
  end

  # Score needed to reach a tier.
  def threshold(tier_name)
    tier_name.to_sym == :bronze ? 0.0 : @thresholds.fetch(tier_name.to_sym)
  end

  # Score for 100%: the world-class standard.
  def ceiling
    @thresholds.fetch(:grandmaster)
  end
end
