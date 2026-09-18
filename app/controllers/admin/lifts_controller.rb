# The review queue: diamond-and-above lifts wait here until approved.
class Admin::LiftsController < Admin::BaseController
  before_action :set_lift, only: %i[ approve reject destroy ]

  def index
    @status = params[:status].presence_in(%w[ pending rejected ]) || "pending"
    @lifts = Lift.where(status: @status).includes(:user).order(created_at: :asc)
    @counts = Lift.where(status: %w[ pending rejected ]).group(:status).count
  end

  def approve
    review "approved"
  end

  def reject
    review "rejected"
  end

  def destroy
    @lift.destroy
    redirect_back_or_to admin_lifts_path, notice: "Deleted #{description}.", status: :see_other
  end

  private
    def set_lift
      @lift = Lift.find(params[:id])
    end

    # Skips validation: whether a lift counts is the admin's call, even for
    # one that predates the current checks.
    def review(status)
      @lift.update_attribute(:status, status)
      redirect_back_or_to admin_lifts_path, notice: "#{status.capitalize} #{description}."
    end

    def description
      "@#{@lift.user.username}'s #{@lift.exercise_name.downcase}"
    end
end
