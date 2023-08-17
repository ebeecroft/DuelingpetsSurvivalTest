require "application_system_test_case"

class AnimalcurrenciesTest < ApplicationSystemTestCase
  setup do
    @animalcurrency = animalcurrencies(:one)
  end

  test "visiting the index" do
    visit animalcurrencies_url
    assert_selector "h1", text: "Animalcurrencies"
  end

  test "creating a Animalcurrency" do
    visit animalcurrencies_url
    click_on "New Animalcurrency"

    fill_in "Animaltype", with: @animalcurrency.animaltype_id
    fill_in "Currency", with: @animalcurrency.currency_id
    fill_in "Currencylevel", with: @animalcurrency.currencylevel_id
    click_on "Create Animalcurrency"

    assert_text "Animalcurrency was successfully created"
    click_on "Back"
  end

  test "updating a Animalcurrency" do
    visit animalcurrencies_url
    click_on "Edit", match: :first

    fill_in "Animaltype", with: @animalcurrency.animaltype_id
    fill_in "Currency", with: @animalcurrency.currency_id
    fill_in "Currencylevel", with: @animalcurrency.currencylevel_id
    click_on "Update Animalcurrency"

    assert_text "Animalcurrency was successfully updated"
    click_on "Back"
  end

  test "destroying a Animalcurrency" do
    visit animalcurrencies_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Animalcurrency was successfully destroyed"
  end
end
