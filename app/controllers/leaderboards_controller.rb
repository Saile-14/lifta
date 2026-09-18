class LeaderboardsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :resume_session, only: :show

  def show
    @discipline = Discipline.find(params[:discipline]) || Discipline.default
    @exercise = @discipline.exercise(params[:board])
    @sex = params[:sex].presence_in(User.sexes.keys)
    @leaderboard = Leaderboard.new(discipline: @discipline, exercise: @exercise, sex: @sex)
  end
end
