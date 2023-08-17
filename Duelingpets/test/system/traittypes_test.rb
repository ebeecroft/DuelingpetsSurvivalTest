require "application_system_test_case"

class TraittypesTest < ApplicationSystemTestCase
  setup do
    @traittype = traittypes(:one)
  end

  test "visiting the index" do
    visit traittypes_url
    assert_selector "h1", text: "Traittypes"
  end

  test "creating a Traittype" do
    visit traittypes_url
    click_on "New Traittype"

    fill_in "Name", with: @traittype.name
    click_on "Create Traittype"

    assert_text "Traittype was successfully created"
    click_on "Back"
  end

  test "updating a Traittype" do
    visit traittypes_url
    click_on "Edit", match: :first

    fill_in "Name", with: @traittype.name
    click_on "Update Traittype"

    assert_text "Traittype was successfully updated"
    click_on "Back"
  end

  test "destroying a Traittype" do
    visit traittypes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Traittype was successfully destroyed"
  end
end
