require "test_helper"

class UserPanel::PuchasesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_panel_puchases_index_url
    assert_response :success
  end

  test "should get show" do
    get user_panel_puchases_show_url
    assert_response :success
  end

  test "should get new" do
    get user_panel_puchases_new_url
    assert_response :success
  end
end
