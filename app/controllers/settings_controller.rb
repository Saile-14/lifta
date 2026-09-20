class SettingsController < ApplicationController
  # A separate copy of the user, so a rejected change (say, a taken username)
  # doesn't leak into the nav while the form re-renders.
  before_action { @user = User.find(Current.user.id) }

  def show
  end

  def update
    if @user.update(settings_params)
      redirect_to settings_path, notice: t(".saved")
    else
      render :show, status: :unprocessable_content
    end
  end

  private
    def settings_params
      params.require(:user).permit(:username, :weight_unit, :time_zone, :public_profile, featured_badges: [])
    end
end
