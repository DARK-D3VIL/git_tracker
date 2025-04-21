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

    max_merge_speed = 0
    max_churn_score = 0
    max_code_quality = 0
    max_review_coverage = 0
    max_response_time = 0
    max_closing_speed = 0
    max_engagement_score = 0
    max_response_to_feedback = 0

    @employees.each do |emp|
      MetricCalculate.new(emp,@reviews,@dev_matrices,@pull_requests).calculate
      max_churn_score = [max_churn_score,emp.churn_score].max
      max_merge_speed = [max_merge_speed,emp.merge_speed].max
      max_code_quality = [max_code_quality,emp.code_quality].max
      max_review_coverage = [max_review_coverage,emp.review_coverage].max
      max_response_time = [max_response_time,emp.response_time].max
      max_closing_speed = [max_closing_speed,emp.closing_speed].max
      max_engagement_score = [max_engagement_score,emp.engagement_score].max
      max_response_to_feedback = [max_response_to_feedback,emp.response_to_feedback].max
    end

    @employees.each do |emp|
      final_dev_score = 0
      final_rev_score = 0

      if max_churn_score > 0
        final_dev_score += 0.15*(emp.churn_score/max_churn_score)
      end
      if max_code_quality > 0
        final_dev_score += 0.30*(emp.code_quality/max_code_quality)
      end
      if max_merge_speed > 0 && emp.merge_speed > 0
        final_dev_score += 0.30*(1 - (emp.merge_speed/max_merge_speed))
      end
      if max_response_to_feedback > 0 && emp.response_to_feedback > 0
        final_dev_score += 0.25*(1 - (emp.response_to_feedback/max_response_to_feedback))
      end

      if max_review_coverage > 0
        final_rev_score += 0.25*(emp.review_coverage/max_review_coverage)
      end
      if max_closing_speed > 0 && emp.closing_speed > 0
        final_rev_score += 0.30*(1 - (emp.closing_speed/max_closing_speed))
      end
      if max_engagement_score > 0
        final_rev_score += 0.25*(emp.engagement_score/max_engagement_score)
      end
      if max_response_time > 0 && emp.response_time > 0
        final_rev_score += 0.20*(1-(emp.response_time/max_response_time))
      end

      emp.dev_score = final_dev_score
      emp.rev_score = final_rev_score

      emp.save!

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
    MetricCalculate.new(@employee, @reviews, @dev_matrices, @pull_requests).calculate
  end

  def raw
    @employees = Employee.all
    @reviews = Review.all
    @prs = PullRequest.all
    @dev_matrices = DeveloperMatrix.all
  end
  
end
