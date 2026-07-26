# frozen_string_literal: true

module MetaPixel
  PIXEL_ID = "913396518474597"

  # Track a Meta Pixel event
  # @param event_name [String] Standard event name (e.g., 'CompleteRegistration', 'Purchase', 'Lead')
  # @param data_object [Hash] Optional user data for advanced matching (email, phone, etc.)
  # @example MetaPixel.track_event('CompleteRegistration', { email: 'user@example.com', phone: '+5212345678901' })
  def self.track_event(event_name, data_object = {})
    # Normalize user data for Meta Pixel (email lowercase, phone stripped)
    user_data = {}
    user_data["em"] = Digest::SHA256.hexdigest(data_object[:email].to_s.strip.downcase) if data_object[:email].present?
    user_data["ph"] = Digest::SHA256.hexdigest(data_object[:phone].to_s.strip.gsub(/\D/, "")) if data_object[:phone].present?

    {
      event_name: event_name,
      pixel_id: PIXEL_ID,
      user_data: user_data,
      currency: data_object[:currency] || "MXN",
      value: data_object[:value]
    }
  end
end
