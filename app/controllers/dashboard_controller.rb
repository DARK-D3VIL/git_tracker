class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :load_data
  def index   
    start_date = 1.year.ago
    end_date = Time.current

    if valid_date?(index_params[:end_date])
      start_date = index_params[:start_date].to_datetime
    end

    if valid_date?(index_params[:end_date])
      end_date = index_params[:end_date].to_datetime
    end

    status = "closed"
    if index_params[:status].present? && index_params[:status] == "all"
      status = index_params[:status]
    end

    sort_by = "dev_score"
    if index_params[:sort_by].present? && index_params[:sort_by] == 'rev_score'
      sort_by = index_params[:sort_by]
    end

    if filters_changed?
      NormalisedMetricService.new(@employees, start_date, end_date, status).normalize
      update_filters
    end

    if index_params[:query].present?
      query = index_params[:query]&.gsub(/[[:space:]]/, '').downcase
      @employees = @employees.where("LOWER(name) LIKE ?", "%#{query}%")
    end
    
    @employees = @employees.sort_by(&sort_by.to_sym).reverse
  end

  def raw
    @pull_requests = PullRequest.all
    @reviews = Review.all
    @dev_matrices = DeveloperMatrix.all
  end

  private

  def valid_date?(date_string)
    if !date_string.present?
      return false
    end
    begin
      Date.parse(date_string)
      true
    rescue ArgumentError
      false
    end
  end

  def filters_changed?
    params[:start_date] != session[:start_date] || params[:status] != session[:status] || params[:end_date] != session[:end_date]
  end

  def update_filters
    session[:start_date] = params[:start_date]
    session[:end_date] = params[:end_date]
    session[:status] = params[:status]
  end

  def index_params
    params.permit(:end_date, :start_date, :status, :sort_by, :query)
  end

  def load_data
    @employees = Employee.all
  end
end
