require 'test_helper'

class AuthControllerTest < ActionController::TestCase
  test "should get connect" do
    get :connect
    assert_response :success
  end

  test "should get receive" do
    get :receive
    assert_response :success
  end

end
