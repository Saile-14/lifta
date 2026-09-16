class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  def home
    # allow_unauthenticated_access skips the before_action that normally
    # resolves Current.session, so it has to be resolved explicitly here.
    redirect_to dashboard_path if authenticated?
  end
end
