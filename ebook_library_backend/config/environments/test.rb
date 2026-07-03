require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true

  config.active_storage.service = :test

  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :stderr

  config.hosts.clear
end
