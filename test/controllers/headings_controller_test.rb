require "test_helper"

class HeadingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get headings_index_url
    assert_response :success
  end
end
