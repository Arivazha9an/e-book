require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module EbookLibrary
  class Application < Rails::Application
    config.load_defaults 7.1

    # This is an API only application: no views, cookies, or sessions.
    config.api_only = true

    # Autoload serializers
    config.autoload_paths += %W[#{config.root}/app/serializers]

    config.time_zone = "UTC"

    # Max size for an uploaded ebook file (50 MB). Enforced in the model
    # validation but also useful to reference from controllers/tests.
    config.x.max_ebook_file_size = 50.megabytes

    config.x.allowed_ebook_content_types = %w[
      application/pdf
      application/epub+zip
    ]
  end
end
