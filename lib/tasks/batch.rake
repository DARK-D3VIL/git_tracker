namespace :batch do
  desc "sync_data"
  task sync_data: :environment do
    GithubService.new.fetch_members
    GithubService.new.fetch_prs
  end
end
