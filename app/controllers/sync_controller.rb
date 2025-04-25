class SyncController < ApplicationController
  before_action :authenticate_user!
  def start
    DataSyncJob.perform_later
    flash[:notice] = "Data Sync Job started"
    redirect_back fallback_location: root_path
  end
end
