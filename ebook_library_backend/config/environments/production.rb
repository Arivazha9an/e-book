require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  config.active_storage.service = :local

  config.log_level = :info
  config.log_tags = [:request_id]

  config.force_ssl = false # set true once you have HTTPS in front of the app
end
