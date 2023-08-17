require "application_system_test_case"

class TagablesTest < ApplicationSystemTestCase
  setup do
    @tagable = tagables(:one)
  end

  test "visiting the index" do
    visit tagables_url
    assert_selector "h1", text: "Tagables"
  end

  test "creating a Tagable" do
    visit tagables_url
    click_on "New Tagable"

    fill_in "Table", with: @tagable.table_id
    fill_in "Table type", with: @tagable.table_type
    fill_in "Tag", with: @tagable.tag_id
    click_on "Create Tagable"

    assert_text "Tagable was successfully created"
    click_on "Back"
  end

  test "updating a Tagable" do
    visit tagables_url
    click_on "Edit", match: :first

    fill_in "Table", with: @tagable.table_id
    fill_in "Table type", with: @tagable.table_type
    fill_in "Tag", with: @tagable.tag_id
    click_on "Update Tagable"

    assert_text "Tagable was successfully updated"
    click_on "Back"
  end

  test "destroying a Tagable" do
    visit tagables_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tagable was successfully destroyed"
  end
end
