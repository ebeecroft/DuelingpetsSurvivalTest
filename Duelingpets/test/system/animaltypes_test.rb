require "application_system_test_case"

class AnimaltypesTest < ApplicationSystemTestCase
  setup do
    @animaltype = animaltypes(:one)
  end

  test "visiting the index" do
    visit animaltypes_url
    assert_selector "h1", text: "Animaltypes"
  end

  test "creating a Animaltype" do
    visit animaltypes_url
    click_on "New Animaltype"

    fill_in "Name", with: @animaltype.name
    click_on "Create Animaltype"

    assert_text "Animaltype was successfully created"
    click_on "Back"
  end

  test "updating a Animaltype" do
    visit animaltypes_url
    click_on "Edit", match: :first

    fill_in "Name", with: @animaltype.name
    click_on "Update Animaltype"

    assert_text "Animaltype was successfully updated"
    click_on "Back"
  end

  test "destroying a Animaltype" do
    visit animaltypes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Animaltype was successfully destroyed"
  end
end
