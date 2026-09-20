class DashboardController < ApplicationController
  def show
    @discipline = Discipline.find(params[:discipline]) || Discipline.default
    @rank_card = RankCard.new(Current.user, @discipline)
    @combo_card = ComboCard.new(Current.user)
    @pending_count = Current.user.lifts.pending.in_discipline(@discipline).count
    @current_bodyweight_kg = Current.user.current_bodyweight_kg
    @recent_lifts = Current.user.lifts.includes(:user).recent_first.limit(8)
  end
end
