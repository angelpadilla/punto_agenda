require "test_helper"

class TrafficVisitTest < ActiveSupport::TestCase
  def setup
    TrafficVisit.delete_all
  end

  test "tracks facebook visits from referer and fbclid" do
    request = ActionDispatch::TestRequest.create(
      "HTTP_REFERER" => "https://www.facebook.com/some/path"
    )

    visit = TrafficVisit.track!(request: request, path: "/", event_type: "visit")

    assert_equal "facebook", visit.source
    assert_equal "/", visit.path
    assert_equal "facebook.com", visit.referer_host
    assert_equal "visit", visit.event_type
  end

  test "returns facebook visits for the requested period" do
    TrafficVisit.create!(source: "facebook", path: "/", event_type: "visit", created_at: 2.days.ago)
    TrafficVisit.create!(source: "facebook", path: "/", event_type: "visit", created_at: 10.days.ago)
    TrafficVisit.create!(source: "other", path: "/", event_type: "visit", created_at: 2.days.ago)

    visits = TrafficVisit.facebook.where(created_at: 7.days.ago..Time.current)

    assert_equal 1, visits.count
  end
end
