class ImportSoroRssPostsJob < ApplicationJob
  queue_as :default

  def perform
    result = SoroRss.run
    Rails.logger.info("[ImportSoroRssPostsJob] #{result.except(:error_details).to_json}")
    result
  end
end