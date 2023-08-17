require 'test_helper'

class TraitmapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @traitmap = traitmaps(:one)
  end

  test "should get index" do
    get traitmaps_url
    assert_response :success
  end

  test "should get new" do
    get new_traitmap_url
    assert_response :success
  end

  test "should create traitmap" do
    assert_difference('Traitmap.count') do
      post traitmaps_url, params: { traitmap: { amount: @traitmap.amount, entity_id: @traitmap.entity_id, entitytype_id: @traitmap.entitytype_id, traittype_id: @traitmap.traittype_id } }
    end

    assert_redirected_to traitmap_url(Traitmap.last)
  end

  test "should show traitmap" do
    get traitmap_url(@traitmap)
    assert_response :success
  end

  test "should get edit" do
    get edit_traitmap_url(@traitmap)
    assert_response :success
  end

  test "should update traitmap" do
    patch traitmap_url(@traitmap), params: { traitmap: { amount: @traitmap.amount, entity_id: @traitmap.entity_id, entitytype_id: @traitmap.entitytype_id, traittype_id: @traitmap.traittype_id } }
    assert_redirected_to traitmap_url(@traitmap)
  end

  test "should destroy traitmap" do
    assert_difference('Traitmap.count', -1) do
      delete traitmap_url(@traitmap)
    end

    assert_redirected_to traitmaps_url
  end
end
