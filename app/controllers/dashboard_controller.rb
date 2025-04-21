class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    @pull_requests = PullRequest.all
    @reviews = Review.all
    @employees = Employee.all
    @dev_matrices = DeveloperMatrix.all

    time_range = nil
    if params[:range].present?
      if params[:range]=="7days"
        time_range = Time.current - 7.days 
      elsif params[:range]=="30days"
        time_range = Time.current - 30.days
      end
    end

    status = "closed"
    if params[:status].present? && params[:status]=="all"
      status = params[:status]
    end

    sort_by = "dev_score"
    if params[:sort_by].present? && params[:sort_by]=='rev_score'
      sort_by = params[:sort_by]
    end

    if time_range.present?
      @pull_requests = @pull_requests.where("pr_created_at >= ?",time_range)
      @reviews = @reviews.where("rev_created_at >= ?",time_range)
    end

    if status == "closed"
      @pull_requests = @pull_requests.where(status: status)
    end

    if params[:query].present?
      query = params[:query].downcase
      @employees = Employee.where("LOWER(name) LIKE ?", "%#{query}%")
    end

    @employees.each do |emp|
      MetricCalculate.new(emp,@reviews,@dev_matrices,@pull_requests).calculate
    end

    @employees = @employees.sort_by(&sort_by.to_sym).reverse
  end

  def show
    @employee = Employee.find(params[:id])
    time_range = nil
    if params[:range].present?
      if params[:range]=="7days"
        time_range = Time.current - 7.days 
      elsif params[:range]=="30days"
        time_range = Time.current - 30.days
      end
    end

    status = "closed"
    if params[:status].present? && params[:status]=="all"
      status = params[:status]
    end

    @pull_requests = PullRequest.all
    @reviews = Review.all

    if time_range.present?
      @pull_requests = @pull_requests.where("pr_created_at >= ?", time_range)
      @reviews = @reviews.where("rev_created_at >= ?", time_range)
    end

    if status == "closed"
      @pull_requests = @pull_requests.where(status: status)
    end
  
    @dev_matrices = DeveloperMatrix.all 
    @metrics = MetricCalculate.new(@employee, @reviews, @dev_matrices, @pull_requests).calculate
  end

  def raw
    @employees = Employee.all
    @reviews = Review.all
    @prs = PullRequest.all
    @dev_matrices = DeveloperMatrix.all
  end
  
end
