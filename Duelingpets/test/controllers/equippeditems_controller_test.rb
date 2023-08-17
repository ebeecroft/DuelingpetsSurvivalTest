require 'test_helper'

class EquippeditemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @equippeditem = equippeditems(:one)
  end

  test "should get index" do
    get equippeditems_url
    assert_response :success
  end

  test "should get new" do
    get new_equippeditem_url
    assert_response :success
  end

  test "should create equippeditem" do
    assert_difference('Equippeditem.count') do
      post equippeditems_url, params: { equippeditem: { current_durability: @equippeditem.current_durability, equip_id: @equippeditem.equip_id, initial_durability: @equippeditem.initial_durability, item_id: @equippeditem.item_id } }
    end

    assert_redirected_to equippeditem_url(Equippeditem.last)
  end

  test "should show equippeditem" do
    get equippeditem_url(@equippeditem)
    assert_response :success
  end

  test "should get edit" do
    get edit_equippeditem_url(@equippeditem)
    assert_response :success
  end

  test "should update equippeditem" do
    patch equippeditem_url(@equippeditem), params: { equippeditem: { current_durability: @equippeditem.current_durability, equip_id: @equippeditem.equip_id, initial_durability: @equippeditem.initial_durability, item_id: @equippeditem.item_id } }
    assert_redirected_to equippeditem_url(@equippeditem)
  end

  test "should destroy equippeditem" do
    assert_difference('Equippeditem.count', -1) do
      delete equippeditem_url(@equippeditem)
    end

    assert_redirected_to equippeditems_url
  end
end
