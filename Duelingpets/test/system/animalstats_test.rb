require "application_system_test_case"

class AnimalstatsTest < ApplicationSystemTestCase
  setup do
    @animalstat = animalstats(:one)
  end

  test "visiting the index" do
    visit animalstats_url
    assert_selector "h1", text: "Animalstats"
  end

  test "creating a Animalstat" do
    visit animalstats_url
    click_on "New Animalstat"

    fill_in "Animaltype", with: @animalstat.animaltype_id
    fill_in "Stat", with: @animalstat.stat_id
    fill_in "Value", with: @animalstat.value
    click_on "Create Animalstat"

    assert_text "Animalstat was successfully created"
    click_on "Back"
  end

  test "updating a Animalstat" do
    visit animalstats_url
    click_on "Edit", match: :first

    fill_in "Animaltype", with: @animalstat.animaltype_id
    fill_in "Stat", with: @animalstat.stat_id
    fill_in "Value", with: @animalstat.value
    click_on "Update Animalstat"

    assert_text "Animalstat was successfully updated"
    click_on "Back"
  end

  test "destroying a Animalstat" do
    visit animalstats_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Animalstat was successfully destroyed"
  end
end
