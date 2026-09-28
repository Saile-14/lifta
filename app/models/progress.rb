# A lifter's history as [date, value] series for the progress charts, in the
# viewer's unit.
#
# Lifts chart one value per day: the best set that day. For barbell lifts
# that's the estimated one-rep max (Epley), not the DOTS or Sinclair score:
# the score moves with bodyweight, so a lifter cutting weight would see their
# squat "improve" without lifting any more. The estimated max is the number
# a lifter actually trains by. Calisthenics has no weight to estimate from,
# so it charts its score, bodyweight-equivalent reps.
#
# Only approved lifts count, as with ranks, so the chart never disagrees with
# the rank beside it.
#
# Bodyweight charts the last weigh-in of each day in the lifter's time zone,
# the same reading User#bodyweight_on uses to score a lift.
class Progress
  attr_reader :user, :unit

  def initialize(user, unit: user.weight_unit)
    @user = user
    @unit = unit
  end

  def lifts(exercise)
    lifts_by_exercise.fetch(exercise.to_s, []).group_by(&:lifted_at).map do |date, lifts|
      [ date, lifts.map { |lift| value_for(lift) }.max ]
    end.sort_by(&:first)
  end

  def bodyweight
    user.bodyweight_entries.order(:recorded_at).pluck(:recorded_at, :kilograms)
      .group_by { |recorded_at, _| recorded_at.in_time_zone(user.time_zone).to_date }
      .map { |date, entries| [ date, convert(entries.last.last) ] }
  end

  private
    def lifts_by_exercise
      @lifts_by_exercise ||= user.lifts.approved.order(:lifted_at).group_by(&:exercise)
    end

    def value_for(lift)
      if lift.discipline.weighted?
        convert(lift.estimated_one_rep_max)
      else
        lift.score.to_f
      end
    end

    def convert(kilograms)
      WeightConversion.from_kg(kilograms, unit).round(1)
    end
end
