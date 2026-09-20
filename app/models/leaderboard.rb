# Public rankings for one discipline -- overall, or a single exercise --
# among lifters who opted in. Lifters are ordered by how far they are toward
# the world-class standard for their sex, so men and women share one board.
#
# The ranking is cached (see LeaderboardCache); the users shown are loaded
# fresh on every read, so a renamed lifter never appears under an old name.
class Leaderboard
  Entry = Data.define(:position, :user, :tier, :score, :lift)

  LIMIT = 100

  attr_reader :discipline, :exercise, :sex

  # exercise: nil for the overall board; sex: nil for everyone.
  def initialize(discipline:, exercise: nil, sex: nil)
    @discipline = discipline
    @exercise = exercise
    @sex = sex
  end

  def entries
    @entries ||= begin
      top = ranking.first(LIMIT)
      users = User.where(id: top.map(&:first)).index_by(&:id)
      lifts = best_lifts_for(users.values)

      top.each_with_index.filter_map do |(user_id, percent, score), index|
        user = users[user_id]
        # Deleted since the ranking was cached.
        next unless user

        Entry.new(position: index + 1, user: user, tier: Tier.new(percent), score: score, lift: lifts[user_id])
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

    # [user_id, percent, score] for everyone on this board, best first.
    def ranking
      @ranking ||= LeaderboardCache.fetch([ discipline.key, exercise&.key, sex ]) { compute_ranking }
    end

    def compute_ranking
      users = lifters.where(id: best_scores.keys).index_by(&:id)
      rows = best_scores.filter_map do |user_id, scores|
        user = users[user_id]
        user && rank(user, scores)
      end

      # Username breaks ties, then drops out -- it isn't cached, since the
      # lifter may rename and the name is only needed for the ordering.
      rows.sort_by { |_, percent, _, username| [ -percent, username ] }.map { |row| row.first(3) }
    end

    def rank(user, scores)
      if exercise
        score = scores[exercise.key]
        return unless score

        percent = discipline.tier_for(score, exercise: exercise.key, sex: user.sex).percent
        [ user.id, percent, score, user.username ]
      else
        percent = discipline.overall_percent(scores, user.sex)
        return unless percent

        [ user.id, percent, (scores.values.sum if discipline.weighted?), user.username ]
      end
    end

    # { user_id => { exercise => best approved score } }, in one query.
    def best_scores
      @best_scores ||= Lift.approved.in_discipline(discipline).where(user_id: lifters.select(:id))
        .group(:user_id, :exercise).maximum(:score)
        .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((user_id, exercise), score), scores|
          scores[user_id][exercise] = score
        end
    end

    # The lift behind each score on a single-exercise board.
    def best_lifts_for(users)
      return {} unless exercise

      Lift.approved.where(user_id: users.map(&:id), exercise: exercise.key).order(score: :desc, lifted_at: :asc)
        .includes(:user).group_by(&:user_id).transform_values(&:first)
    end
end
