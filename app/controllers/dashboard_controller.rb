class DashboardController < ApplicationController
  def show
    @current_bodyweight_kg = Current.user.current_bodyweight_kg
    @ranks = Lift.exercises.keys.index_with { |exercise| Current.user.rank_for(exercise) }
    @recent_lifts = Current.user.lifts.order(lifted_at: :desc, created_at: :desc).limit(10)
  end
end
