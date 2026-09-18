class LiftsController < ApplicationController
  before_action :set_lift, only: %i[ edit update destroy ]

  def index
    @discipline = Discipline.find(params[:discipline])
    lifts = Current.user.lifts.includes(:user).recent_first
    @lifts = @discipline ? lifts.in_discipline(@discipline) : lifts
  end

  def new
    @discipline = Discipline.find(params[:discipline]) || Discipline.default
    @lift = Current.user.lifts.new(exercise: @discipline.exercise_keys.first)
  end

  def create
    @lift = Current.user.lifts.new(lift_attributes)
    change = RankChange.new(Current.user, @lift)

    if @lift.save
      record_weigh_in
      redirect_to dashboard_path(discipline: @lift.discipline), notice: change.message, flash: { tier: change.new_tier }
    else
      render_form :new
    end
  end

  def edit
    @discipline = @lift.discipline
  end

  def update
    @lift.assign_attributes(lift_attributes)
    change = RankChange.new(Current.user, @lift, verb: :saved)

    if @lift.save
      redirect_to lifts_path(discipline: @lift.discipline), notice: change.message, flash: { tier: change.new_tier }
    else
      render_form :edit
    end
  end

  def destroy
    @lift.destroy
    redirect_to lifts_path(discipline: @lift.discipline), notice: t(".deleted"), status: :see_other
  end

  private
    def set_lift
      @lift = Current.user.lifts.find(params[:id])
    end

    def form_params
      params.require(:lift).permit(:exercise, :weight, :unit, :reps, :lifted_at, :bodyweight)
    end

    def lift_attributes
      values = form_params
      unit = values[:unit].presence_in(%w[ kg lb ]) || Current.user.weight_unit

      {
        exercise: values[:exercise].presence_in(Discipline.exercise_keys),
        weight_lifted: (WeightConversion.to_kg(values[:weight], unit) if values[:weight].present?),
        reps: values[:reps].presence || 1,
        lifted_at: values[:lifted_at].presence,
        # Blank means "use the bodyweight logged for that date".
        bodyweight_kg: (WeightConversion.to_kg(values[:bodyweight], unit) if values[:bodyweight].present?)
      }
    end

    # A bodyweight typed into the lift form goes into the bodyweight log too.
    def record_weigh_in
      Current.user.record_weigh_in(@lift.bodyweight_kg, on: @lift.lifted_at) if form_params[:bodyweight].present?
    end

    def render_form(template)
      @discipline = @lift.discipline || Discipline.default
      @values = form_params.to_h
      render template, status: :unprocessable_content
    end
end
