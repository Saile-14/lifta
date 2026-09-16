class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to dashboard_path, notice: "Welcome to Lifta."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :sex, :weight_unit)
  end
end
