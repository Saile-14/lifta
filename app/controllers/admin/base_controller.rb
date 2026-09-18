class Admin::BaseController < ApplicationController
  before_action :require_admin

  private
    # Hidden rather than forbidden: to anyone else, admin pages don't exist.
    def require_admin
      raise ActiveRecord::RecordNotFound unless Current.user&.admin?
    end
end
