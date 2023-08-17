require 'test_helper'

class AnimalcurrenciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @animalcurrency = animalcurrencies(:one)
  end

  test "should get index" do
    get animalcurrencies_url
    assert_response :success
  end

  test "should get new" do
    get new_animalcurrency_url
    assert_response :success
  end

  test "should create animalcurrency" do
    assert_difference('Animalcurrency.count') do
      post animalcurrencies_url, params: { animalcurrency: { animaltype_id: @animalcurrency.animaltype_id, currency_id: @animalcurrency.currency_id, currencylevel_id: @animalcurrency.currencylevel_id } }
    end

    assert_redirected_to animalcurrency_url(Animalcurrency.last)
  end

  test "should show animalcurrency" do
    get animalcurrency_url(@animalcurrency)
    assert_response :success
  end

  test "should get edit" do
    get edit_animalcurrency_url(@animalcurrency)
    assert_response :success
  end

  test "should update animalcurrency" do
    patch animalcurrency_url(@animalcurrency), params: { animalcurrency: { animaltype_id: @animalcurrency.animaltype_id, currency_id: @animalcurrency.currency_id, currencylevel_id: @animalcurrency.currencylevel_id } }
    assert_redirected_to animalcurrency_url(@animalcurrency)
  end

  test "should destroy animalcurrency" do
    assert_difference('Animalcurrency.count', -1) do
      delete animalcurrency_url(@animalcurrency)
    end

    assert_redirected_to animalcurrencies_url
  end
end
