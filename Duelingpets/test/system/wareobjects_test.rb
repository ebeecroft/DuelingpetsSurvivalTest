require "application_system_test_case"

class WareobjectsTest < ApplicationSystemTestCase
  setup do
    @wareobject = wareobjects(:one)
  end

  test "visiting the index" do
    visit wareobjects_url
    assert_selector "h1", text: "Wareobjects"
  end

  test "creating a Wareobject" do
    visit wareobjects_url
    click_on "New Wareobject"

    fill_in "Price", with: @wareobject.price
    fill_in "Quantity", with: @wareobject.quantity
    fill_in "Type", with: @wareobject.type
    fill_in "Wareobject", with: @wareobject.wareobject_id
    fill_in "Wareshelf", with: @wareobject.wareshelf_id
    click_on "Create Wareobject"

    assert_text "Wareobject was successfully created"
    click_on "Back"
  end

  test "updating a Wareobject" do
    visit wareobjects_url
    click_on "Edit", match: :first

    fill_in "Price", with: @wareobject.price
    fill_in "Quantity", with: @wareobject.quantity
    fill_in "Type", with: @wareobject.type
    fill_in "Wareobject", with: @wareobject.wareobject_id
    fill_in "Wareshelf", with: @wareobject.wareshelf_id
    click_on "Update Wareobject"

    assert_text "Wareobject was successfully updated"
    click_on "Back"
  end

  test "destroying a Wareobject" do
    visit wareobjects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Wareobject was successfully destroyed"
  end
end
