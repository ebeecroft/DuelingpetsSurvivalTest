require "application_system_test_case"

class WareshelvesTest < ApplicationSystemTestCase
  setup do
    @wareshelf = wareshelves(:one)
  end

  test "visiting the index" do
    visit wareshelves_url
    assert_selector "h1", text: "Wareshelves"
  end

  test "creating a Wareshelf" do
    visit wareshelves_url
    click_on "New Wareshelf"

    fill_in "Warehouse", with: @wareshelf.warehouse_id
    fill_in "Warelimit", with: @wareshelf.warelimit
    fill_in "Waretype", with: @wareshelf.waretype
    click_on "Create Wareshelf"

    assert_text "Wareshelf was successfully created"
    click_on "Back"
  end

  test "updating a Wareshelf" do
    visit wareshelves_url
    click_on "Edit", match: :first

    fill_in "Warehouse", with: @wareshelf.warehouse_id
    fill_in "Warelimit", with: @wareshelf.warelimit
    fill_in "Waretype", with: @wareshelf.waretype
    click_on "Update Wareshelf"

    assert_text "Wareshelf was successfully updated"
    click_on "Back"
  end

  test "destroying a Wareshelf" do
    visit wareshelves_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Wareshelf was successfully destroyed"
  end
end
