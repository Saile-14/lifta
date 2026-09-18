# What a newly logged or edited lift did to the lifter's ranks, as the
# message shown afterwards. Build it before saving the lift (to capture the
# ranks it started from) and ask for the message after.
class RankChange
  # verb: :logged or :saved, for the plain "Lift logged." message.
  def initialize(user, lift, verb: :logged)
    @user = user
    @lift = lift
    @verb = verb
    @before = ranks
  end

  def message
    return pending_message if @lift.pending?

    [ exercise_message, overall_message ].compact.join(" ")
  end

  # The tier reached, when the lift earned a new rank -- for coloring the
  # message.
  def new_tier
    return if @lift.pending?

    was, now = @before[:exercise], after[:exercise]
    now.name if now && (was.nil? || now.level > was.level)
  end

  private
    def ranks
      return {} unless @lift.discipline

      card = RankCard.new(@user, @lift.discipline)
      { exercise: card.rows.find { |row| row.exercise.key == @lift.exercise }&.tier, overall: card.overall }
    end

    def after
      @after ||= ranks
    end

    def exercise_name
      @lift.exercise_name
    end

    def verb
      I18n.t("rank_change.verbs.#{@verb}")
    end

    def pending_message
      I18n.t("rank_change.pending", tier: @lift.tier.label, exercise: exercise_name.downcase)
    end

    def exercise_message
      was, now = @before[:exercise], after[:exercise]
      return I18n.t("rank_change.verb_only", verb: verb) unless now

      if was.nil?
        I18n.t("rank_change.first_rank", exercise: exercise_name, tier: now.to_s)
      elsif now.level > was.level
        I18n.t("rank_change.rank_up", exercise: exercise_name, from: was.label, to: now.to_s)
      elsif now > was
        I18n.t("rank_change.new_best", exercise: exercise_name.downcase, tier: now.to_s, percent: was.display_percent)
      else
        I18n.t("rank_change.unchanged", verb: verb, exercise: exercise_name, tier: now.to_s)
      end
    end

    def overall_message
      was, now = @before[:overall], after[:overall]
      return unless now

      if was.nil?
        I18n.t("rank_change.overall_first", discipline: @lift.discipline.name, tier: now.to_s)
      elsif now.level > was.level
        I18n.t("rank_change.overall_up", discipline: @lift.discipline.name, from: was.label, to: now.to_s)
      end
    end
end
