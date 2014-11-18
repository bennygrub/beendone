require 'test_helper'

class MatesControllerTest < ActionController::TestCase
  setup do
    @mate = mates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mate" do
    assert_difference('Mate.count') do
      post :create, mate: { email: @mate.email, name: @mate.name, trip_id: @mate.trip_id }
    end

    assert_redirected_to mate_path(assigns(:mate))
  end

  test "should show mate" do
    get :show, id: @mate
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mate
    assert_response :success
  end

  test "should update mate" do
    patch :update, id: @mate, mate: { email: @mate.email, name: @mate.name, trip_id: @mate.trip_id }
    assert_redirected_to mate_path(assigns(:mate))
  end

  test "should destroy mate" do
    assert_difference('Mate.count', -1) do
      delete :destroy, id: @mate
    end

    assert_redirected_to mates_path
  end
end
