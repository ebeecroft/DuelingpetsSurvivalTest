require 'test_helper'

class ExchangeratesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exchangerate = exchangerates(:one)
  end

  test "should get index" do
    get exchangerates_url
    assert_response :success
  end

  test "should get new" do
    get new_exchangerate_url
    assert_response :success
  end

  test "should create exchangerate" do
    assert_difference('Exchangerate.count') do
      post exchangerates_url, params: { exchangerate: { currency1_id: @exchangerate.currency1_id, currency2_id: @exchangerate.currency2_id, currentrate: @exchangerate.currentrate, maxrate: @exchangerate.maxrate, minrate: @exchangerate.minrate } }
    end

    assert_redirected_to exchangerate_url(Exchangerate.last)
  end

  test "should show exchangerate" do
    get exchangerate_url(@exchangerate)
    assert_response :success
  end

  test "should get edit" do
    get edit_exchangerate_url(@exchangerate)
    assert_response :success
  end

  test "should update exchangerate" do
    patch exchangerate_url(@exchangerate), params: { exchangerate: { currency1_id: @exchangerate.currency1_id, currency2_id: @exchangerate.currency2_id, currentrate: @exchangerate.currentrate, maxrate: @exchangerate.maxrate, minrate: @exchangerate.minrate } }
    assert_redirected_to exchangerate_url(@exchangerate)
  end

  test "should destroy exchangerate" do
    assert_difference('Exchangerate.count', -1) do
      delete exchangerate_url(@exchangerate)
    end

    assert_redirected_to exchangerates_url
  end
end
