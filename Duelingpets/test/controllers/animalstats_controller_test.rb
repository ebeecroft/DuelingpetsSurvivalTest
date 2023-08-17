require 'test_helper'

class AnimalstatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @animalstat = animalstats(:one)
  end

  test "should get index" do
    get animalstats_url
    assert_response :success
  end

  test "should get new" do
    get new_animalstat_url
    assert_response :success
  end

  test "should create animalstat" do
    assert_difference('Animalstat.count') do
      post animalstats_url, params: { animalstat: { animaltype_id: @animalstat.animaltype_id, stat_id: @animalstat.stat_id, value: @animalstat.value } }
    end

    assert_redirected_to animalstat_url(Animalstat.last)
  end

  test "should show animalstat" do
    get animalstat_url(@animalstat)
    assert_response :success
  end

  test "should get edit" do
    get edit_animalstat_url(@animalstat)
    assert_response :success
  end

  test "should update animalstat" do
    patch animalstat_url(@animalstat), params: { animalstat: { animaltype_id: @animalstat.animaltype_id, stat_id: @animalstat.stat_id, value: @animalstat.value } }
    assert_redirected_to animalstat_url(@animalstat)
  end

  test "should destroy animalstat" do
    assert_difference('Animalstat.count', -1) do
      delete animalstat_url(@animalstat)
    end

    assert_redirected_to animalstats_url
  end
end
