# The signed-in lifter's charts: each lift over time, and bodyweight. Private
# like the lift and bodyweight logs they're drawn from; a public profile shows
# only best lifts, never history or bodyweight.
class ProgressController < ApplicationController
  def show
    @discipline = Discipline.find(params[:discipline]) || Discipline.default
    @progress = Progress.new(Current.user)
  end
end
