# Public rankings for one discipline -- overall, or a single exercise --
# among lifters who opted in. Lifters are ordered by how far they are toward
# the world-class standard for their sex, so men and women share one board.
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
      top = ranked.first(LIMIT)
      lifts = best_lifts_for(top.map(&:first))
      top.each_with_index.map do |(user, tier, score), index|
        Entry.new(position: index + 1, user: user, tier: tier, score: score, lift: lifts[user.id])
      end
    end
  end

  def size
    ranked.size
  end

  def position_of(user)
    index = ranked.index { |entry_user, _, _| entry_user == user }
    index + 1 if index
  end

  private
    def lifters
      scope = User.listed
      sex ? scope.where(sex: sex) : scope
    end

    # [user, tier, score] for everyone with a rank on this board, best first.
    def ranked
      @ranked ||= begin
        users = lifters.where(id: best_scores.keys).index_by(&:id)
        rows = best_scores.filter_map do |user_id, scores|
          user = users[user_id]
          user && rank(user, scores)
        end
        rows.sort_by { |user, tier, _| [ -tier.percent, user.username ] }
      end
    end

    def rank(user, scores)
      if exercise
        score = scores[exercise.key]
        [ user, discipline.tier_for(score, exercise: exercise.key, sex: user.sex), score ] if score
      else
        percent = discipline.overall_percent(scores, user.sex)
        [ user, Tier.new(percent), (scores.values.sum if discipline.weighted?) ] if percent
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
