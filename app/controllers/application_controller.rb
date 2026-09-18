class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :use_time_zone

  private
    # Dates and times read and display in the lifter's own time zone.
    def use_time_zone(&)
      Time.use_zone(resume_session&.user&.time_zone || "Etc/UTC", &)
    end
end
