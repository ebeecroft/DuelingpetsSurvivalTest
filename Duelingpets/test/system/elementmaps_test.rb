require "application_system_test_case"

class ElementmapsTest < ApplicationSystemTestCase
  setup do
    @elementmap = elementmaps(:one)
  end

  test "visiting the index" do
    visit elementmaps_url
    assert_selector "h1", text: "Elementmaps"
  end

  test "creating a Elementmap" do
    visit elementmaps_url
    click_on "New Elementmap"

    fill_in "Damageoffset", with: @elementmap.damageoffset_id
    fill_in "Element", with: @elementmap.element_id
    fill_in "Elementchart", with: @elementmap.elementchart_id
    click_on "Create Elementmap"

    assert_text "Elementmap was successfully created"
    click_on "Back"
  end

  test "updating a Elementmap" do
    visit elementmaps_url
    click_on "Edit", match: :first

    fill_in "Damageoffset", with: @elementmap.damageoffset_id
    fill_in "Element", with: @elementmap.element_id
    fill_in "Elementchart", with: @elementmap.elementchart_id
    click_on "Update Elementmap"

    assert_text "Elementmap was successfully updated"
    click_on "Back"
  end

  test "destroying a Elementmap" do
    visit elementmaps_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Elementmap was successfully destroyed"
  end
end
