class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: t(".rate_limited") }

  def new
    @user = User.new(public_profile: true)
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to dashboard_path, notice: t(".welcome", username: @user.username)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :username, :password, :sex, :weight_unit, :public_profile, :time_zone).tap do |permitted|
      # Filled in from the browser; fall back to UTC rather than fail sign-up.
      permitted[:time_zone] = "Etc/UTC" unless ActiveSupport::TimeZone[permitted[:time_zone].to_s]
    end
  end
end
