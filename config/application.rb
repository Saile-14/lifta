require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lifta
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # English and Japanese. Visitors get their browser's language (English if
    # it's neither) and can switch with the button in the header; see the
    # Localization concern.
    config.i18n.available_locales = %i[ en ja ]
    config.i18n.default_locale = :en

    # Password resets email a link, so they stay switched off (and the "Forgot
    # password?" link hidden) until production has outgoing mail configured.
    config.x.password_resets_enabled = false

    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  end
end
