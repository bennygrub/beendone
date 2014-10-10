require 'test_helper'

class FlightFixesControllerTest < ActionController::TestCase
  setup do
    @flight_fix = flight_fixes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:flight_fixes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create flight_fix" do
    assert_difference('FlightFix.count') do
      post :create, flight_fix: { airline_mapping_id: @flight_fix.airline_mapping_id, direction: @flight_fix.direction, flight_id: @flight_fix.flight_id, status: @flight_fix.status, trip_id: @flight_fix.trip_id }
    end

    assert_redirected_to flight_fix_path(assigns(:flight_fix))
  end

  test "should show flight_fix" do
    get :show, id: @flight_fix
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @flight_fix
    assert_response :success
  end

  test "should update flight_fix" do
    patch :update, id: @flight_fix, flight_fix: { airline_mapping_id: @flight_fix.airline_mapping_id, direction: @flight_fix.direction, flight_id: @flight_fix.flight_id, status: @flight_fix.status, trip_id: @flight_fix.trip_id }
    assert_redirected_to flight_fix_path(assigns(:flight_fix))
  end

  test "should destroy flight_fix" do
    assert_difference('FlightFix.count', -1) do
      delete :destroy, id: @flight_fix
    end

    assert_redirected_to flight_fixes_path
  end
end
