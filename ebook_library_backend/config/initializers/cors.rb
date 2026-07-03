Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, replace "*" with your actual Flutter web origin(s).
    origins "*"

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Content-Disposition]

    resource "/rails/active_storage/*",
      headers: :any,
      methods: %i[get head]
  end
end
