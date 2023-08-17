require 'test_helper'

class SkilltypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @skilltype = skilltypes(:one)
  end

  test "should get index" do
    get skilltypes_url
    assert_response :success
  end

  test "should get new" do
    get new_skilltype_url
    assert_response :success
  end

  test "should create skilltype" do
    assert_difference('Skilltype.count') do
      post skilltypes_url, params: { skilltype: { name: @skilltype.name } }
    end

    assert_redirected_to skilltype_url(Skilltype.last)
  end

  test "should show skilltype" do
    get skilltype_url(@skilltype)
    assert_response :success
  end

  test "should get edit" do
    get edit_skilltype_url(@skilltype)
    assert_response :success
  end

  test "should update skilltype" do
    patch skilltype_url(@skilltype), params: { skilltype: { name: @skilltype.name } }
    assert_redirected_to skilltype_url(@skilltype)
  end

  test "should destroy skilltype" do
    assert_difference('Skilltype.count', -1) do
      delete skilltype_url(@skilltype)
    end

    assert_redirected_to skilltypes_url
  end
end
