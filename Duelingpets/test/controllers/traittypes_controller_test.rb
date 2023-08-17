require 'test_helper'

class TraittypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @traittype = traittypes(:one)
  end

  test "should get index" do
    get traittypes_url
    assert_response :success
  end

  test "should get new" do
    get new_traittype_url
    assert_response :success
  end

  test "should create traittype" do
    assert_difference('Traittype.count') do
      post traittypes_url, params: { traittype: { name: @traittype.name } }
    end

    assert_redirected_to traittype_url(Traittype.last)
  end

  test "should show traittype" do
    get traittype_url(@traittype)
    assert_response :success
  end

  test "should get edit" do
    get edit_traittype_url(@traittype)
    assert_response :success
  end

  test "should update traittype" do
    patch traittype_url(@traittype), params: { traittype: { name: @traittype.name } }
    assert_redirected_to traittype_url(@traittype)
  end

  test "should destroy traittype" do
    assert_difference('Traittype.count', -1) do
      delete traittype_url(@traittype)
    end

    assert_redirected_to traittypes_url
  end
end
