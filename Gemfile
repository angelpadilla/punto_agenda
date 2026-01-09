source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end


# Logs https://github.com/collectiveidea/audited
gem "audited"

# filtros y busquedas https://activerecord-hackery.github.io/ransack/
gem "ransack"

# # paginacion https://github.com/ddnexus/pagy
# # https://ddnexus.github.io/pagy/quick-start/
gem "pagy"

# sample data https://github.com/faker-ruby/faker
gem "faker"

gem "http"

gem "devise", "~> 4.9"

## https://github.com/igorkasyanchuk/active_storage_validations
gem "active_storage_validations"


# https://github.com/prawnpdf/prawn
gem "prawn"
gem "prawn-svg"
gem "prawn-table"

# https://github.com/whomwah/rqrcode
gem "rqrcode", "~> 2.0"

gem "csv", "~> 3.3"
gem "rubyXL", "3.4.33"
gem "nokogiri", "~> 1.18"

## This rails templates comes with Action Text and Active Storage enabled by default.
## - Action Text allows you to create rich text content with images, videos, and other media.
## - Active Storage provides a way to upload files to cloud storage services like Amazon S3, Google Cloud Storage, or local disk.

## Action Text docs
# https://guides.rubyonrails.org/action_text_overview.html
## Action Text docs
# https://guides.rubyonrails.org/action_text_overview.html
## Active Storage docs
# https://guides.rubyonrails.org/active_storage_overview.html


gem "sentry-ruby"
gem "sentry-rails"
