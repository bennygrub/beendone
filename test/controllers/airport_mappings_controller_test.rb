require 'test_helper'

class AirportMappingsControllerTest < ActionController::TestCase
  setup do
    @airport_mapping = airport_mappings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:airport_mappings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create airport_mapping" do
    assert_difference('AirportMapping.count') do
      post :create, airport_mapping: { airline_id: @airport_mapping.airline_id, airport_id: @airport_mapping.airport_id, city: @airport_mapping.city, message_id: @airport_mapping.message_id, name: @airport_mapping.name, note: @airport_mapping.note }
    end

    assert_redirected_to airport_mapping_path(assigns(:airport_mapping))
  end

  test "should show airport_mapping" do
    get :show, id: @airport_mapping
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @airport_mapping
    assert_response :success
  end

  test "should update airport_mapping" do
    patch :update, id: @airport_mapping, airport_mapping: { airline_id: @airport_mapping.airline_id, airport_id: @airport_mapping.airport_id, city: @airport_mapping.city, message_id: @airport_mapping.message_id, name: @airport_mapping.name, note: @airport_mapping.note }
    assert_redirected_to airport_mapping_path(assigns(:airport_mapping))
  end

  test "should destroy airport_mapping" do
    assert_difference('AirportMapping.count', -1) do
      delete :destroy, id: @airport_mapping
    end

    assert_redirected_to airport_mappings_path
  end
end
