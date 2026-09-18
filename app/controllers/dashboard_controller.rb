class DashboardController < ApplicationController
  def show
    @current_bodyweight_kg = Current.user.current_bodyweight_kg
    @rank_card = RankCard.new(Current.user, Discipline.default)
    @recent_lifts = Current.user.lifts.recent_first.limit(10)
  end
end
