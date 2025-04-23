class EmployeeController < ApplicationController
  before_action :authenticate_user!
  def index
    start_date = 1.year.ago.to_date
    end_date = Time.current

    if params[:start_date].present?
      start_date = permitted_params[:start_date].to_datetime
    end

    if params[:end_date].present?
      end_date = permitted_params[:end_date].to_datetime
    end
    puts start_date
    puts end_date

    status = "closed"
    if permitted_params[:status].present? && permitted_params[:status] == "all"
      status = permitted_params[:status]
    end

    pull_requests = PullRequest.where(pr_created_at: start_date..end_date)
    reviews = Review.where(rev_created_at: start_date..end_date)
    dev_matrices = DeveloperMatrix.all
    @employee = Employee.find(params[:id])

    status = "closed"
    if permitted_params[:status].present? && permitted_params[:status] == "all"
      status = permitted_params[:status]
    end

    if status == "closed"
      pull_requests = pull_requests.where(status: status)
    end

    if filters_changed?
      MetricCalculate.new(@employee, reviews, dev_matrices, pull_requests).calculate_and_normalize
      update_filters
    end
  end

  private

  def filters_changed?
    params[:start_date] != session[:start_date] || params[:status] != session[:status] || params[:end_date] != session[:end_date]
  end

  def update_filters
    session[:start_date] = params[:start_date]
    session[:end_date] = params[:end_date]
    session[:status] = params[:status]
  end

  def permitted_params
    params.permit(:id, :start_date, :end_date, :status)
  end
end
