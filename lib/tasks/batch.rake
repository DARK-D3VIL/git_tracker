namespace :batch do
  desc "sync_data"
  task sync_data: :environment do
    DataSyncJob.perform_later
  end
end
