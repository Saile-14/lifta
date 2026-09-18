class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ show destroy ]

  def index
    @query = params[:q].to_s.strip.downcase
    users = User.order(created_at: :desc)
    if @query.present?
      pattern = "%#{User.sanitize_sql_like(@query)}%"
      users = users.where("email_address LIKE :pattern OR username LIKE :pattern", pattern: pattern)
    end

    @users = users.limit(200).to_a
    @lift_counts = Lift.where(user_id: @users.map(&:id)).group(:user_id).count
    @pending_counts = Lift.pending.where(user_id: @users.map(&:id)).group(:user_id).count
  end

  def show
    @lifts = @user.lifts.includes(:user).recent_first
  end

  # Deleting a user deletes their lifts, bodyweight log and sessions with them.
  def destroy
    if @user == Current.user
      redirect_to admin_user_path(@user), alert: t(".self")
    else
      @user.destroy
      redirect_to admin_users_path, notice: t(".deleted", username: @user.username), status: :see_other
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
