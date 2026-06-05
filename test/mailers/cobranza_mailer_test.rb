require "test_helper"

class CobranzaMailerTest < ActionMailer::TestCase
  test "success_payment" do
    mail = CobranzaMailer.success_payment
    assert_equal "Success payment", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "failed_payment" do
    mail = CobranzaMailer.failed_payment
    assert_equal "Failed payment", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
