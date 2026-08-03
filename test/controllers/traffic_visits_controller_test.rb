require "test_helper"

class TrafficVisitsControllerTest < ActionDispatch::IntegrationTest
  def setup
    TrafficVisit.delete_all
  end

  test "home tracks facebook visits from fbclid" do
    get root_path, params: { fbclid: "abc123" }

    assert_response :success
    assert_equal 1, TrafficVisit.where(source: "facebook", path: "/", event_type: "visit").count
  end

  test "signup page tracks facebook visits from referer" do
    get new_user_registration_path, headers: { "HTTP_REFERER" => "https://m.facebook.com/" }

    assert_response :success
    assert_equal 1, TrafficVisit.where(source: "facebook", path: "/users/sign_up", event_type: "visit").count
  end
end
