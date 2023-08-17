require "application_system_test_case"

class EquipsTest < ApplicationSystemTestCase
  setup do
    @equip = equips(:one)
  end

  test "visiting the index" do
    visit equips_url
    assert_selector "h1", text: "Equips"
  end

  test "creating a Equip" do
    visit equips_url
    click_on "New Equip"

    fill_in "Capacity", with: @equip.capacity
    fill_in "Partner", with: @equip.partner_id
    click_on "Create Equip"

    assert_text "Equip was successfully created"
    click_on "Back"
  end

  test "updating a Equip" do
    visit equips_url
    click_on "Edit", match: :first

    fill_in "Capacity", with: @equip.capacity
    fill_in "Partner", with: @equip.partner_id
    click_on "Update Equip"

    assert_text "Equip was successfully updated"
    click_on "Back"
  end

  test "destroying a Equip" do
    visit equips_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Equip was successfully destroyed"
  end
end
