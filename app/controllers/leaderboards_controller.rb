class LeaderboardsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :resume_session, only: :show

  def show
    @sex = params[:sex].presence_in(User.sexes.keys)
    @combined = params[:discipline] == ComboCard::KEY

    if @combined
      @leaderboard = ComboLeaderboard.new(sex: @sex)
    else
      @discipline = Discipline.find(params[:discipline]) || Discipline.default
      @exercise = @discipline.exercise(params[:board])
      @leaderboard = Leaderboard.new(discipline: @discipline, exercise: @exercise, sex: @sex)
    end
  end
end
