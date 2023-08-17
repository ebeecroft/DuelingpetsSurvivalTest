require "application_system_test_case"

class EntitytypesTest < ApplicationSystemTestCase
  setup do
    @entitytype = entitytypes(:one)
  end

  test "visiting the index" do
    visit entitytypes_url
    assert_selector "h1", text: "Entitytypes"
  end

  test "creating a Entitytype" do
    visit entitytypes_url
    click_on "New Entitytype"

    fill_in "Name", with: @entitytype.name
    click_on "Create Entitytype"

    assert_text "Entitytype was successfully created"
    click_on "Back"
  end

  test "updating a Entitytype" do
    visit entitytypes_url
    click_on "Edit", match: :first

    fill_in "Name", with: @entitytype.name
    click_on "Update Entitytype"

    assert_text "Entitytype was successfully updated"
    click_on "Back"
  end

  test "destroying a Entitytype" do
    visit entitytypes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Entitytype was successfully destroyed"
  end
end
