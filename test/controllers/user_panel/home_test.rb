require "test_helper"

class UserPanelHomeTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  self.fixture_table_names = []

  setup do
    Warden.test_mode!
    @original_telegram_noti = Gtools.method(:telegram_noti)
    Gtools.define_singleton_method(:telegram_noti) { |**_kwargs| true }

    @corp = Corp.create!(
      tipo_negocio: "otro",
      status: :activo,
      visto: true,
      name: "Demo Corp",
      phone: "1234567890",
      tel_prefix: "+52",
      email: "corp@example.com",
      stripe_customer_id: "cus_test_123"
    )

    @user = User.create!(
      corp: @corp,
      full_name: "User One",
      email: "user@example.com",
      tel: "1234567890",
      tel_prefix: "+52",
      tipo: "propietario",
      password: "password123",
      password_confirmation: "password123",
      work_start_time: Time.zone.parse("00:00"),
      work_end_time: Time.zone.parse("23:59")
    )

    login_as @user, scope: :user
  end

  teardown do
    Gtools.define_singleton_method(:telegram_noti, @original_telegram_noti)
    Warden.test_reset!
  end

  test "shows work schedule onboarding step as pending when hours are default" do
    get user_panel_home_path

    assert_response :success
    assert_includes response.body, "Configura tu horario laboral"
    assert_select "a[href='#{edit_user_path(@user)}']", text: "Editar"
  end

  test "marks work schedule onboarding step as completed when hours are customized" do
    @user.update!(work_start_time: Time.zone.parse("09:00"), work_end_time: Time.zone.parse("18:00"))

    get user_panel_home_path

    assert_response :success
    assert_select ".onboarding_item.is-done .onboarding_title", text: "Configura tu horario laboral"
    assert_select "a[href='#{edit_user_path(@user)}']", false
  end
end
