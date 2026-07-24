require "test_helper"

class TelegramWebhookControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @old_secret = ENV["TELEGRAM_WEBHOOK_SECRET_TOKEN"]
    ENV["TELEGRAM_WEBHOOK_SECRET_TOKEN"] = "secret-test-token"
  end

  teardown do
    ENV["TELEGRAM_WEBHOOK_SECRET_TOKEN"] = @old_secret
  end

  test "rechaza webhook sin token secreto" do
    post "/telegram/webhook", params: { update_id: 101, message: { text: "hola", chat: { id: 123 } } }

    assert_response :unauthorized
  end

  test "rechaza update_id repetido" do
    Rails.cache.delete("telegram:webhook:update_id:202")

    post "/telegram/webhook",
         params: { update_id: 202, message: { text: "hola", chat: { id: 123 } } },
         headers: { "X-Telegram-Bot-Api-Secret-Token" => "secret-test-token" }
    assert_response :success

    post "/telegram/webhook",
         params: { update_id: 202, message: { text: "hola", chat: { id: 123 } } },
         headers: { "X-Telegram-Bot-Api-Secret-Token" => "secret-test-token" }
    assert_response :conflict
  end
end
