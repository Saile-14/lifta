# What a newly logged or edited lift did to the lifter's ranks, as the
# message shown afterwards. Build it before saving the lift (to capture the
# ranks it started from) and ask for the message after.
class RankChange
  def initialize(user, lift, verb: "Lift logged")
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

    def pending_message
      "#{@lift.tier.label}-level #{exercise_name.downcase} logged. " \
        "It'll count toward your rank once an admin approves it."
    end

    def exercise_message
      was, now = @before[:exercise], after[:exercise]
      return "#{@verb}." unless now

      if was.nil?
        "#{exercise_name} ranked: #{now}."
      elsif now.level > was.level
        "Rank up! #{exercise_name}: #{was.label} → #{now}."
      elsif now > was
        "New #{exercise_name.downcase} best: #{now}, up from #{was.display_percent}%."
      else
        "#{@verb}. #{exercise_name}: #{now}."
      end
    end

    def overall_message
      was, now = @before[:overall], after[:overall]
      return unless now

      if was.nil?
        "#{@lift.discipline.name} overall: #{now}."
      elsif now.level > was.level
        "#{@lift.discipline.name} overall: #{was.label} → #{now}!"
      end
    end
end
