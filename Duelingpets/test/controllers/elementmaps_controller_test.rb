require 'test_helper'

class ElementmapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @elementmap = elementmaps(:one)
  end

  test "should get index" do
    get elementmaps_url
    assert_response :success
  end

  test "should get new" do
    get new_elementmap_url
    assert_response :success
  end

  test "should create elementmap" do
    assert_difference('Elementmap.count') do
      post elementmaps_url, params: { elementmap: { damageoffset_id: @elementmap.damageoffset_id, element_id: @elementmap.element_id, elementchart_id: @elementmap.elementchart_id } }
    end

    assert_redirected_to elementmap_url(Elementmap.last)
  end

  test "should show elementmap" do
    get elementmap_url(@elementmap)
    assert_response :success
  end

  test "should get edit" do
    get edit_elementmap_url(@elementmap)
    assert_response :success
  end

  test "should update elementmap" do
    patch elementmap_url(@elementmap), params: { elementmap: { damageoffset_id: @elementmap.damageoffset_id, element_id: @elementmap.element_id, elementchart_id: @elementmap.elementchart_id } }
    assert_redirected_to elementmap_url(@elementmap)
  end

  test "should destroy elementmap" do
    assert_difference('Elementmap.count', -1) do
      delete elementmap_url(@elementmap)
    end

    assert_redirected_to elementmaps_url
  end
end
