require 'test_helper'

class CurrencylevelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @currencylevel = currencylevels(:one)
  end

  test "should get index" do
    get currencylevels_url
    assert_response :success
  end

  test "should get new" do
    get new_currencylevel_url
    assert_response :success
  end

  test "should create currencylevel" do
    assert_difference('Currencylevel.count') do
      post currencylevels_url, params: { currencylevel: { name: @currencylevel.name } }
    end

    assert_redirected_to currencylevel_url(Currencylevel.last)
  end

  test "should show currencylevel" do
    get currencylevel_url(@currencylevel)
    assert_response :success
  end

  test "should get edit" do
    get edit_currencylevel_url(@currencylevel)
    assert_response :success
  end

  test "should update currencylevel" do
    patch currencylevel_url(@currencylevel), params: { currencylevel: { name: @currencylevel.name } }
    assert_redirected_to currencylevel_url(@currencylevel)
  end

  test "should destroy currencylevel" do
    assert_difference('Currencylevel.count', -1) do
      delete currencylevel_url(@currencylevel)
    end

    assert_redirected_to currencylevels_url
  end
end
