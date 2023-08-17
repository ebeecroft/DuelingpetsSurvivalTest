require 'test_helper'

class TagablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tagable = tagables(:one)
  end

  test "should get index" do
    get tagables_url
    assert_response :success
  end

  test "should get new" do
    get new_tagable_url
    assert_response :success
  end

  test "should create tagable" do
    assert_difference('Tagable.count') do
      post tagables_url, params: { tagable: { table_id: @tagable.table_id, table_type: @tagable.table_type, tag_id: @tagable.tag_id } }
    end

    assert_redirected_to tagable_url(Tagable.last)
  end

  test "should show tagable" do
    get tagable_url(@tagable)
    assert_response :success
  end

  test "should get edit" do
    get edit_tagable_url(@tagable)
    assert_response :success
  end

  test "should update tagable" do
    patch tagable_url(@tagable), params: { tagable: { table_id: @tagable.table_id, table_type: @tagable.table_type, tag_id: @tagable.tag_id } }
    assert_redirected_to tagable_url(@tagable)
  end

  test "should destroy tagable" do
    assert_difference('Tagable.count', -1) do
      delete tagable_url(@tagable)
    end

    assert_redirected_to tagables_url
  end
end
