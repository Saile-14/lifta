# robots.txt, served by the app rather than from public/ because the Sitemap
# line has to be an absolute URL, and the app's host isn't fixed anywhere in
# its configuration.
class RobotsController < ApplicationController
  allow_unauthenticated_access

  def show
    expires_in 1.day, public: true
  end
end
