class DataSyncJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    Rails.logger.info "=== DataSyncJob started ==="
    GithubService.new.fetch_members
    GithubService.new.fetch_prs
  end
end
