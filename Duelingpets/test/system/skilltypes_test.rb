require "application_system_test_case"

class SkilltypesTest < ApplicationSystemTestCase
  setup do
    @skilltype = skilltypes(:one)
  end

  test "visiting the index" do
    visit skilltypes_url
    assert_selector "h1", text: "Skilltypes"
  end

  test "creating a Skilltype" do
    visit skilltypes_url
    click_on "New Skilltype"

    fill_in "Name", with: @skilltype.name
    click_on "Create Skilltype"

    assert_text "Skilltype was successfully created"
    click_on "Back"
  end

  test "updating a Skilltype" do
    visit skilltypes_url
    click_on "Edit", match: :first

    fill_in "Name", with: @skilltype.name
    click_on "Update Skilltype"

    assert_text "Skilltype was successfully updated"
    click_on "Back"
  end

  test "destroying a Skilltype" do
    visit skilltypes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Skilltype was successfully destroyed"
  end
end
