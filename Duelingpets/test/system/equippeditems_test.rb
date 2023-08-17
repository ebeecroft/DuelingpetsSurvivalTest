require "application_system_test_case"

class EquippeditemsTest < ApplicationSystemTestCase
  setup do
    @equippeditem = equippeditems(:one)
  end

  test "visiting the index" do
    visit equippeditems_url
    assert_selector "h1", text: "Equippeditems"
  end

  test "creating a Equippeditem" do
    visit equippeditems_url
    click_on "New Equippeditem"

    fill_in "Current durability", with: @equippeditem.current_durability
    fill_in "Equip", with: @equippeditem.equip_id
    fill_in "Initial durability", with: @equippeditem.initial_durability
    fill_in "Item", with: @equippeditem.item_id
    click_on "Create Equippeditem"

    assert_text "Equippeditem was successfully created"
    click_on "Back"
  end

  test "updating a Equippeditem" do
    visit equippeditems_url
    click_on "Edit", match: :first

    fill_in "Current durability", with: @equippeditem.current_durability
    fill_in "Equip", with: @equippeditem.equip_id
    fill_in "Initial durability", with: @equippeditem.initial_durability
    fill_in "Item", with: @equippeditem.item_id
    click_on "Update Equippeditem"

    assert_text "Equippeditem was successfully updated"
    click_on "Back"
  end

  test "destroying a Equippeditem" do
    visit equippeditems_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Equippeditem was successfully destroyed"
  end
end
