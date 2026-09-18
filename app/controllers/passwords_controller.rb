class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_password_resets
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t(".rate_limited") }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: t(".sent")
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t(".reset")
    else
      redirect_to edit_password_path(params[:token]), alert: t(".mismatch")
    end
  end

  private
    # Hidden until outgoing mail is set up (see config.x.password_resets_enabled).
    def require_password_resets
      redirect_to new_session_path, alert: t("passwords.unavailable") unless Rails.configuration.x.password_resets_enabled
    end

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.invalid_token")
    end
end
