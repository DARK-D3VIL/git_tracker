class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    range = "all"
    if params[:range].present?
      range = params[:range]
    end
    status = "closed"
    if params[:status].present?
      status = params[:status]
    end
    sort_by = nil
    if params[:sort_by].present?
      status = params[:sort_by]
    end

    time_range = nil
    if range=="7days"
      time_range = Time.now -  7.days
    end

    @employees = Employee.all
  end
end
