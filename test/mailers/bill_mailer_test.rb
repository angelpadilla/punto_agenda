require "test_helper"

class BillMailerTest < ActionMailer::TestCase
  test "retiro_success" do
    mail = BillMailer.retiro_success
    assert_equal "Retiro success", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "retiro_error" do
    mail = BillMailer.retiro_error
    assert_equal "Retiro error", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
