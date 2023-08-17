require "application_system_test_case"

class ExchangeratesTest < ApplicationSystemTestCase
  setup do
    @exchangerate = exchangerates(:one)
  end

  test "visiting the index" do
    visit exchangerates_url
    assert_selector "h1", text: "Exchangerates"
  end

  test "creating a Exchangerate" do
    visit exchangerates_url
    click_on "New Exchangerate"

    fill_in "Currency1", with: @exchangerate.currency1_id
    fill_in "Currency2", with: @exchangerate.currency2_id
    fill_in "Currentrate", with: @exchangerate.currentrate
    fill_in "Maxrate", with: @exchangerate.maxrate
    fill_in "Minrate", with: @exchangerate.minrate
    click_on "Create Exchangerate"

    assert_text "Exchangerate was successfully created"
    click_on "Back"
  end

  test "updating a Exchangerate" do
    visit exchangerates_url
    click_on "Edit", match: :first

    fill_in "Currency1", with: @exchangerate.currency1_id
    fill_in "Currency2", with: @exchangerate.currency2_id
    fill_in "Currentrate", with: @exchangerate.currentrate
    fill_in "Maxrate", with: @exchangerate.maxrate
    fill_in "Minrate", with: @exchangerate.minrate
    click_on "Update Exchangerate"

    assert_text "Exchangerate was successfully updated"
    click_on "Back"
  end

  test "destroying a Exchangerate" do
    visit exchangerates_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Exchangerate was successfully destroyed"
  end
end
