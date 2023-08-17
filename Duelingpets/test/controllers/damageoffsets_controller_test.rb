require 'test_helper'

class DamageoffsetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @damageoffset = damageoffsets(:one)
  end

  test "should get index" do
    get damageoffsets_url
    assert_response :success
  end

  test "should get new" do
    get new_damageoffset_url
    assert_response :success
  end

  test "should create damageoffset" do
    assert_difference('Damageoffset.count') do
      post damageoffsets_url, params: { damageoffset: { name: @damageoffset.name, value: @damageoffset.value } }
    end

    assert_redirected_to damageoffset_url(Damageoffset.last)
  end

  test "should show damageoffset" do
    get damageoffset_url(@damageoffset)
    assert_response :success
  end

  test "should get edit" do
    get edit_damageoffset_url(@damageoffset)
    assert_response :success
  end

  test "should update damageoffset" do
    patch damageoffset_url(@damageoffset), params: { damageoffset: { name: @damageoffset.name, value: @damageoffset.value } }
    assert_redirected_to damageoffset_url(@damageoffset)
  end

  test "should destroy damageoffset" do
    assert_difference('Damageoffset.count', -1) do
      delete damageoffset_url(@damageoffset)
    end

    assert_redirected_to damageoffsets_url
  end
end
