require "application_system_test_case"

class CharacterstatsTest < ApplicationSystemTestCase
  setup do
    @characterstat = characterstats(:one)
  end

  test "visiting the index" do
    visit characterstats_url
    assert_selector "h1", text: "Characterstats"
  end

  test "creating a Characterstat" do
    visit characterstats_url
    click_on "New Characterstat"

    fill_in "Character", with: @characterstat.character_id
    fill_in "Stat", with: @characterstat.stat_id
    fill_in "Value", with: @characterstat.value
    click_on "Create Characterstat"

    assert_text "Characterstat was successfully created"
    click_on "Back"
  end

  test "updating a Characterstat" do
    visit characterstats_url
    click_on "Edit", match: :first

    fill_in "Character", with: @characterstat.character_id
    fill_in "Stat", with: @characterstat.stat_id
    fill_in "Value", with: @characterstat.value
    click_on "Update Characterstat"

    assert_text "Characterstat was successfully updated"
    click_on "Back"
  end

  test "destroying a Characterstat" do
    visit characterstats_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Characterstat was successfully destroyed"
  end
end
