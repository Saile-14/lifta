# Public ranking across all three disciplines at once, among lifters who
# opted in -- the fourth board alongside the three per-discipline ones.
#
# Deliberately the same shape as Leaderboard (entries, size, position_of) so
# the leaderboard page renders either without branching, but the ranking is
# ComboCard's: the average of progress through all three disciplines. Only
# approved lifts count, so anything heavy enough to need an admin's sign-off
# stays off the board until it gets one.
class ComboLeaderboard
  Entry = Data.define(:position, :user, :tier, :card)

  LIMIT = Leaderboard::LIMIT

  attr_reader :sex

  # sex: nil for everyone.
  def initialize(sex: nil)
    @sex = sex
  end

  def entries
    @entries ||= ranked.first(LIMIT).each_with_index.map do |(user, card), index|
      Entry.new(position: index + 1, user: user, tier: card.tier, card: card)
    end
  end

  def size
    ranked.size
  end

  def position_of(user)
    index = ranked.index { |entry_user, _| entry_user == user }
    index + 1 if index
  end

  private
    def lifters
      scope = User.listed
      sex ? scope.where(sex: sex) : scope
    end

    # [user, card] for everyone with something logged, best first.
    def ranked
      @ranked ||= begin
        cards = lifters.map { |user| [ user, ComboCard.new(user, scores: best_scores[user.id]) ] }
        cards.select { |_, card| card.ranked? }
          .sort_by { |user, card| [ -card.percent, user.username ] }
      end
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
