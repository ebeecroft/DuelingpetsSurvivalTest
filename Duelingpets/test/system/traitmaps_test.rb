require "application_system_test_case"

class TraitmapsTest < ApplicationSystemTestCase
  setup do
    @traitmap = traitmaps(:one)
  end

  test "visiting the index" do
    visit traitmaps_url
    assert_selector "h1", text: "Traitmaps"
  end

  test "creating a Traitmap" do
    visit traitmaps_url
    click_on "New Traitmap"

    fill_in "Amount", with: @traitmap.amount
    fill_in "Entity", with: @traitmap.entity_id
    fill_in "Entitytype", with: @traitmap.entitytype_id
    fill_in "Traittype", with: @traitmap.traittype_id
    click_on "Create Traitmap"

    assert_text "Traitmap was successfully created"
    click_on "Back"
  end

  test "updating a Traitmap" do
    visit traitmaps_url
    click_on "Edit", match: :first

    fill_in "Amount", with: @traitmap.amount
    fill_in "Entity", with: @traitmap.entity_id
    fill_in "Entitytype", with: @traitmap.entitytype_id
    fill_in "Traittype", with: @traitmap.traittype_id
    click_on "Update Traitmap"

    assert_text "Traitmap was successfully updated"
    click_on "Back"
  end

  test "destroying a Traitmap" do
    visit traitmaps_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Traitmap was successfully destroyed"
  end
end
