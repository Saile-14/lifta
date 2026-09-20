# A lifter's combined standing across all three disciplines: the average of
# how far they are through each one.
#
# Every discipline counts, and one they have never trained counts as zero, so
# a pure powerlifter tops out around a third of the way up. That is the point
# -- the combined ladder (see ComboTier) is meant to reward breadth, and its
# top rung should mean world-class in powerlifting, weightlifting and
# calisthenics at once.
class ComboCard
  # One discipline's contribution: progress through it either way, plus the
  # discipline's own tier once every exercise in it has an approved lift.
  Row = Data.define(:discipline, :percent, :tier) do
    def ranked?
      !tier.nil?
    end
  end

  attr_reader :user

  # scores: { exercise => best approved score }, injectable so a leaderboard
  # can load every lifter's scores in one query instead of one per card.
  def initialize(user, scores: nil)
    @user = user
    @scores = scores
  end

  def tier
    ComboTier.new(percent)
  end

  def percent
    rows.sum(&:percent) / rows.size
  end

  def rows
    @rows ||= Discipline.all.map do |discipline|
      Row.new(discipline: discipline, percent: discipline.progress_percent(scores, user.sex),
        tier: tier_for(discipline))
    end
  end

  def row_for(discipline)
    rows.find { |row| row.discipline == discipline }
  end

  # A lifter with nothing logged sits at zero on every discipline, which is a
  # real dormant rank rather than a missing one -- but there's no point
  # showing it, or putting them on the leaderboard.
  def ranked?
    scores.any?
  end

  private
    def scores
      @scores ||= user.lifts.approved.group(:exercise).maximum(:score)
    end

    def tier_for(discipline)
      percent = discipline.overall_percent(scores, user.sex)
      Tier.new(percent) if percent
    end
end
