require 'test_helper'

class WareshelvesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wareshelf = wareshelves(:one)
  end

  test "should get index" do
    get wareshelves_url
    assert_response :success
  end

  test "should get new" do
    get new_wareshelf_url
    assert_response :success
  end

  test "should create wareshelf" do
    assert_difference('Wareshelf.count') do
      post wareshelves_url, params: { wareshelf: { warehouse_id: @wareshelf.warehouse_id, warelimit: @wareshelf.warelimit, waretype: @wareshelf.waretype } }
    end

    assert_redirected_to wareshelf_url(Wareshelf.last)
  end

  test "should show wareshelf" do
    get wareshelf_url(@wareshelf)
    assert_response :success
  end

  test "should get edit" do
    get edit_wareshelf_url(@wareshelf)
    assert_response :success
  end

  test "should update wareshelf" do
    patch wareshelf_url(@wareshelf), params: { wareshelf: { warehouse_id: @wareshelf.warehouse_id, warelimit: @wareshelf.warelimit, waretype: @wareshelf.waretype } }
    assert_redirected_to wareshelf_url(@wareshelf)
  end

  test "should destroy wareshelf" do
    assert_difference('Wareshelf.count', -1) do
      delete wareshelf_url(@wareshelf)
    end

    assert_redirected_to wareshelves_url
  end
end
