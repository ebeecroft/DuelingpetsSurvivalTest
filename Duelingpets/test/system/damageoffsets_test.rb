require "application_system_test_case"

class DamageoffsetsTest < ApplicationSystemTestCase
  setup do
    @damageoffset = damageoffsets(:one)
  end

  test "visiting the index" do
    visit damageoffsets_url
    assert_selector "h1", text: "Damageoffsets"
  end

  test "creating a Damageoffset" do
    visit damageoffsets_url
    click_on "New Damageoffset"

    fill_in "Name", with: @damageoffset.name
    fill_in "Value", with: @damageoffset.value
    click_on "Create Damageoffset"

    assert_text "Damageoffset was successfully created"
    click_on "Back"
  end

  test "updating a Damageoffset" do
    visit damageoffsets_url
    click_on "Edit", match: :first

    fill_in "Name", with: @damageoffset.name
    fill_in "Value", with: @damageoffset.value
    click_on "Update Damageoffset"

    assert_text "Damageoffset was successfully updated"
    click_on "Back"
  end

  test "destroying a Damageoffset" do
    visit damageoffsets_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Damageoffset was successfully destroyed"
  end
end
