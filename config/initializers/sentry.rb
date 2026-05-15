# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://3c878c80ba3adabcd3adbc7265330848@o4507453930340352.ingest.us.sentry.io/4511393398652928'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true
end