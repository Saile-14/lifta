# A lifter's weigh-ins, held in memory, and the one rule for which of them
# a date resolves to: the latest weigh-in on or before the end of that day
# (in the lifter's time zone), like a meet weigh-in -- falling back to the
# first one logged after, when the log doesn't reach back that far.
#
# In memory so the same rule can be asked about hundreds of dates, and about
# the log as it was a moment ago, without a query per date. See
# User#resnapshot_bodyweight.
class BodyweightLog
  # weigh_ins: [recorded_at, kilograms] pairs, in any order.
  def initialize(weigh_ins, time_zone:)
    @weigh_ins = weigh_ins.sort_by(&:first)
    @time_zone = time_zone
  end

  def self.for(user)
    new(user.bodyweight_entries.pluck(:recorded_at, :kilograms), time_zone: user.time_zone)
  end

  # Kilograms, or nil for an empty log. No date means the latest weigh-in.
  def on(date)
    return @weigh_ins.last&.last unless date

    day_end = date.to_date.in_time_zone(@time_zone).end_of_day
    after = @weigh_ins.bsearch_index { |recorded_at, _| recorded_at > day_end } || @weigh_ins.size

    (after.zero? ? @weigh_ins.first : @weigh_ins[after - 1])&.last
  end
end
