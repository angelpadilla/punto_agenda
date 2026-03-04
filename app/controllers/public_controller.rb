class PublicController < ApplicationController
  def home
    @stripe_token = Rails.application.credentials.dig(:stripe_token)
    @awstoken = Rails.application.credentials.dig(:aws, :token1)
  end
end
