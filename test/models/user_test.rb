require "test_helper"

class UserTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "work_hours_default? returns true for the default full-day schedule" do
    user = User.new(
      full_name: "Horario Default",
      email: "default@example.com",
      tel: "1234567890",
      tel_prefix: "+52",
      tipo: "colaborador"
    )
    user.work_start_time = Time.zone.parse("00:00")
    user.work_end_time = Time.zone.parse("23:59")

    assert user.work_hours_default?
    assert_not user.work_hours_customized?
  end

  test "work_hours_customized? returns true when the user changes their work hours" do
    user = User.new(
      full_name: "Horario Personalizado",
      email: "custom@example.com",
      tel: "1234567891",
      tel_prefix: "+52",
      tipo: "colaborador"
    )
    user.work_start_time = Time.zone.parse("09:00")
    user.work_end_time = Time.zone.parse("18:00")

    assert_not user.work_hours_default?
    assert user.work_hours_customized?
  end
end
