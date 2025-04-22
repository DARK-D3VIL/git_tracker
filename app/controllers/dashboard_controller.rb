class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    @employees = Employee.all
    pull_requests = PullRequest.all
    reviews = Review.all
    dev_matrices = DeveloperMatrix.all
   
    time_range = nil
    if index_params[:range].present?
      if index_params[:range] == "7days"
        time_range = Time.current - 7.days 
      elsif index_params[:range] == "30days"
        time_range = Time.current - 30.days
      end
    end

    status = "closed"
    if index_params[:status].present? && index_params[:status] == "all"
      status = index_params[:status]
    end

    sort_by = "dev_score"
    if index_params[:sort_by].present? && index_params[:sort_by] == 'rev_score'
      sort_by = index_params[:sort_by]
    end

    if time_range.present?
      pull_requests = pull_requests.where("pr_created_at >= ?", time_range)
      reviews = reviews.where("rev_created_at >= ?", time_range)
    end

    if status == "closed"
      pull_requests = pull_requests.where(status: status)
    end

    if index_params[:query].present?
      query = index_params[:query]&.gsub(/[[:space:]]/, '').downcase
      @employees = Employee.where("LOWER(name) LIKE ?", "%#{query}%")
    end

    if filters_changed?
      NormalisedMetricService.new(@employees, reviews, dev_matrices, pull_requests).normalize
      update_filters
    end
    
    @employees = @employees.sort_by(&sort_by.to_sym).reverse
  end

  def show
    employees = Employee.all
    pull_requests = PullRequest.all
    reviews = Review.all
    dev_matrices = DeveloperMatrix.all

    time_range = nil
    if show_params[:range].present?
      if show_params[:range] == "7days"
        time_range = Time.current - 7.days 
      elsif show_params[:range] == "30days"
        time_range = Time.current - 30.days
      end
    end

    status = "closed"
    if show_params[:status].present? && show_params[:status] == "all"
      status = show_params[:status]
    end

    if time_range.present?
      pull_requests = pull_requests.where("pr_created_at >= ?", time_range)
      reviews = reviews.where("rev_created_at >= ?", time_range)
    end

    if status == "closed"
      pull_requests = pull_requests.where(status: status)
    end

    if filters_changed?
      NormalisedMetricService.new(employees, reviews, dev_matrices, pull_requests).normalize
      update_filters
    end

    @employee = Employee.find(params[:id])
  end

  def raw
    @pull_requests = PullRequest.all
    @reviews = Review.all
    @employees = Employee.all
    @dev_matrices = DeveloperMatrix.all
  end

  private

  def filters_changed?
    params[:range] != session[:range] || params[:status] != session[:status]
  end

  def update_filters
    session[:range] = params[:range]
    session[:status] = params[:status]
  end

  def index_params
    params.permit(:range, :status, :sort_by, :query)
  end

  def show_params
    params.permit(:range, :status)
  end
end
