require 'test_helper'

class EntitytypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entitytype = entitytypes(:one)
  end

  test "should get index" do
    get entitytypes_url
    assert_response :success
  end

  test "should get new" do
    get new_entitytype_url
    assert_response :success
  end

  test "should create entitytype" do
    assert_difference('Entitytype.count') do
      post entitytypes_url, params: { entitytype: { name: @entitytype.name } }
    end

    assert_redirected_to entitytype_url(Entitytype.last)
  end

  test "should show entitytype" do
    get entitytype_url(@entitytype)
    assert_response :success
  end

  test "should get edit" do
    get edit_entitytype_url(@entitytype)
    assert_response :success
  end

  test "should update entitytype" do
    patch entitytype_url(@entitytype), params: { entitytype: { name: @entitytype.name } }
    assert_redirected_to entitytype_url(@entitytype)
  end

  test "should destroy entitytype" do
    assert_difference('Entitytype.count', -1) do
      delete entitytype_url(@entitytype)
    end

    assert_redirected_to entitytypes_url
  end
end
