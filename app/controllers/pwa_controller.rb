# The web app manifest and service worker. Rails ships a controller for these
# (Rails::PwaController), but it doesn't go through ApplicationController, so
# it would always answer in English. This one picks the language like every
# other page, so the installed app is named in the language it was installed
# in. Browsers fetch the manifest without cookies, which is why the layout
# links it with ?locale=.
class PwaController < ApplicationController
  allow_unauthenticated_access
  # The service worker is JavaScript served to a GET, which Rails' forgery
  # protection would otherwise refuse as a cross-origin script.
  skip_forgery_protection

  def manifest
    render template: "pwa/manifest", layout: false
  end

  def service_worker
    render template: "pwa/service-worker", layout: false
  end
end
