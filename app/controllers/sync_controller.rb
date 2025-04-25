class SyncController < ApplicationController
  def start
    DataSyncJob.perform_later
    flash[:notice] = "Data Sync Job started"
    redirect_back fallback_location: root_path
  end
end
