require 'test_helper'

class CharacterstatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @characterstat = characterstats(:one)
  end

  test "should get index" do
    get characterstats_url
    assert_response :success
  end

  test "should get new" do
    get new_characterstat_url
    assert_response :success
  end

  test "should create characterstat" do
    assert_difference('Characterstat.count') do
      post characterstats_url, params: { characterstat: { character_id: @characterstat.character_id, stat_id: @characterstat.stat_id, value: @characterstat.value } }
    end

    assert_redirected_to characterstat_url(Characterstat.last)
  end

  test "should show characterstat" do
    get characterstat_url(@characterstat)
    assert_response :success
  end

  test "should get edit" do
    get edit_characterstat_url(@characterstat)
    assert_response :success
  end

  test "should update characterstat" do
    patch characterstat_url(@characterstat), params: { characterstat: { character_id: @characterstat.character_id, stat_id: @characterstat.stat_id, value: @characterstat.value } }
    assert_redirected_to characterstat_url(@characterstat)
  end

  test "should destroy characterstat" do
    assert_difference('Characterstat.count', -1) do
      delete characterstat_url(@characterstat)
    end

    assert_redirected_to characterstats_url
  end
end
