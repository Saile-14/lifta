class LiftsController < ApplicationController
  def index
    @lifts = Current.user.lifts.order(lifted_at: :desc, created_at: :desc)
  end

  def new
    @lift = Current.user.lifts.new
  end

  def create
    @lift = Current.user.lifts.new(lift_params)

    if @lift.save
      redirect_to lifts_path, notice: "Lift logged: #{@lift.benchmark.name}."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def lift_params
    raw = params.require(:lift).permit(:exercise, :weight, :unit, :reps, :lifted_at)
    unit = raw[:unit].presence || Current.user.weight_unit

    {
      exercise: raw[:exercise],
      weight_lifted: WeightConversion.to_kg(raw[:weight], unit),
      reps: raw[:reps].presence || 1,
      lifted_at: raw[:lifted_at].presence
    }
  end
end
