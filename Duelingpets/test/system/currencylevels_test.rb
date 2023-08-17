require "application_system_test_case"

class CurrencylevelsTest < ApplicationSystemTestCase
  setup do
    @currencylevel = currencylevels(:one)
  end

  test "visiting the index" do
    visit currencylevels_url
    assert_selector "h1", text: "Currencylevels"
  end

  test "creating a Currencylevel" do
    visit currencylevels_url
    click_on "New Currencylevel"

    fill_in "Name", with: @currencylevel.name
    click_on "Create Currencylevel"

    assert_text "Currencylevel was successfully created"
    click_on "Back"
  end

  test "updating a Currencylevel" do
    visit currencylevels_url
    click_on "Edit", match: :first

    fill_in "Name", with: @currencylevel.name
    click_on "Update Currencylevel"

    assert_text "Currencylevel was successfully updated"
    click_on "Back"
  end

  test "destroying a Currencylevel" do
    visit currencylevels_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Currencylevel was successfully destroyed"
  end
end
