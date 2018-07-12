require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "expects authentication redirect page " do
    get auth_confirm_url
    assert_response :success
  end

  test "expects to sign out" do
    get sign_out_url
    assert_response :redirect
    assert_redirected_to 'http://www.example.com/'
  end

  test "expect auth failure" do
    get auth_failure_url
    assert_response :success
  end
end
