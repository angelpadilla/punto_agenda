require "test_helper"

class ImportSoroRssPostsJobTest < ActiveJob::TestCase
  test "ejecuta importador de Soro RSS" do
    expected = {
      success: true,
      feed_url: "https://example.com/feed",
      total_items: 0,
      created: 0,
      duplicates: 0,
      errors: 0,
      error_details: []
    }

    SoroRss.stub(:run, expected) do
      result = ImportSoroRssPostsJob.perform_now
      assert_equal expected, result
    end
  end
end