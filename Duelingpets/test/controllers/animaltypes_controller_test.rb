require 'test_helper'

class AnimaltypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @animaltype = animaltypes(:one)
  end

  test "should get index" do
    get animaltypes_url
    assert_response :success
  end

  test "should get new" do
    get new_animaltype_url
    assert_response :success
  end

  test "should create animaltype" do
    assert_difference('Animaltype.count') do
      post animaltypes_url, params: { animaltype: { name: @animaltype.name } }
    end

    assert_redirected_to animaltype_url(Animaltype.last)
  end

  test "should show animaltype" do
    get animaltype_url(@animaltype)
    assert_response :success
  end

  test "should get edit" do
    get edit_animaltype_url(@animaltype)
    assert_response :success
  end

  test "should update animaltype" do
    patch animaltype_url(@animaltype), params: { animaltype: { name: @animaltype.name } }
    assert_redirected_to animaltype_url(@animaltype)
  end

  test "should destroy animaltype" do
    assert_difference('Animaltype.count', -1) do
      delete animaltype_url(@animaltype)
    end

    assert_redirected_to animaltypes_url
  end
end
