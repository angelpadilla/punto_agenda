stripe_key = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key)
StripeClient = Stripe::StripeClient.new(stripe_key) if stripe_key.present?
