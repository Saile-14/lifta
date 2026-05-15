require "test_helper"

class LiftTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email notif when back in stock" do
    lift = lifts(:squat)

    lift.update(count: 0)

    assert_emails 2 do
      lift.update(count: 95)
    end
  end
end
