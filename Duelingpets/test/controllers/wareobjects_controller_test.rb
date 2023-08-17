require 'test_helper'

class WareobjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wareobject = wareobjects(:one)
  end

  test "should get index" do
    get wareobjects_url
    assert_response :success
  end

  test "should get new" do
    get new_wareobject_url
    assert_response :success
  end

  test "should create wareobject" do
    assert_difference('Wareobject.count') do
      post wareobjects_url, params: { wareobject: { price: @wareobject.price, quantity: @wareobject.quantity, type: @wareobject.type, wareobject_id: @wareobject.wareobject_id, wareshelf_id: @wareobject.wareshelf_id } }
    end

    assert_redirected_to wareobject_url(Wareobject.last)
  end

  test "should show wareobject" do
    get wareobject_url(@wareobject)
    assert_response :success
  end

  test "should get edit" do
    get edit_wareobject_url(@wareobject)
    assert_response :success
  end

  test "should update wareobject" do
    patch wareobject_url(@wareobject), params: { wareobject: { price: @wareobject.price, quantity: @wareobject.quantity, type: @wareobject.type, wareobject_id: @wareobject.wareobject_id, wareshelf_id: @wareobject.wareshelf_id } }
    assert_redirected_to wareobject_url(@wareobject)
  end

  test "should destroy wareobject" do
    assert_difference('Wareobject.count', -1) do
      delete wareobject_url(@wareobject)
    end

    assert_redirected_to wareobjects_url
  end
end
