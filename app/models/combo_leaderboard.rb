# Public ranking across all three disciplines at once, among lifters who
# opted in -- the fourth board alongside the three per-discipline ones.
#
# Deliberately the same shape as Leaderboard (entries, size, position_of) so
# the leaderboard page renders either without branching, but the ranking is
# ComboCard's: the average of progress through all three disciplines. Only
# approved lifts count, so anything heavy enough to need an admin's sign-off
# stays off the board until it gets one.
#
# The ranking is cached (see LeaderboardCache). This is the most expensive
# board in the app -- it scores every lifter across every discipline -- so
# it gains the most from not being rebuilt per request.
class ComboLeaderboard
  # percents: progress through each discipline, in Discipline.all order.
  Entry = Data.define(:position, :user, :tier, :percents)

  LIMIT = Leaderboard::LIMIT

  attr_reader :sex

  # sex: nil for everyone.
  def initialize(sex: nil)
    @sex = sex
  end

  def entries
    @entries ||= begin
      top = ranking.first(LIMIT)
      users = User.where(id: top.map(&:first)).index_by(&:id)

      top.each_with_index.filter_map do |(user_id, percent, percents), index|
        user = users[user_id]
        next unless user

        Entry.new(position: index + 1, user: user, tier: ComboTier.new(percent), percents: percents)
      end
    end
  end

  def size
    ranking.size
  end

  def position_of(user)
    index = ranking.index { |user_id, _, _| user_id == user.id }
    index + 1 if index
  end

  private
    def lifters
      scope = User.listed
      sex ? scope.where(sex: sex) : scope
    end

    # [user_id, combined percent, per-discipline percents], best first.
    def ranking
      @ranking ||= LeaderboardCache.fetch([ ComboCard::KEY, sex ]) { compute_ranking }
    end

    def compute_ranking
      rows = lifters.filter_map do |user|
        card = ComboCard.new(user, scores: best_scores[user.id])
        next unless card.ranked?

        [ user.id, card.percent, card.rows.map(&:percent), user.username ]
      end

      rows.sort_by { |_, percent, _, username| [ -percent, username ] }.map { |row| row.first(3) }
    end

    # { user_id => { exercise => best approved score } }, in one query, so
    # ranking every lifter doesn't cost a query each.
    def best_scores
      @best_scores ||= Lift.approved.where(user_id: lifters.select(:id))
        .group(:user_id, :exercise).maximum(:score)
        .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((user_id, exercise), score), scores|
          scores[user_id][exercise] = score
        end
    end
end
