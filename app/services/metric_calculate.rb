class MetricCalculate
  def initialize(employee,reviews,developer_matrices,pull_requests)
    @employee = employee
    @reviews = reviews
    @developer_matrices = developer_matrices.where(github_id: employee.github_id)
    @pull_requests = pull_requests

    pr_ids = []
    for matrix in @developer_matrices
      if matrix.pr_id.present?
        pr_ids.append(matrix.pr_id)
      end
    end

    @dev_pr = pull_requests.where(pr_id: pr_ids)
  end

  def calculate
    @employee.merge_speed = cal_merge_speed
    @employee.churn_score = cal_churn_score
    @employee.code_quality = cal_code_quality
    @employee.response_to_feedback = cal_response_to_feedback

    emp_github_id = @employee.github_id
    emp_reviews = []
    reviewed_pr_ids = []

    for review in @reviews
      if review.github_id == emp_github_id
        emp_reviews.append(review)
      end
    end

    for review in emp_reviews
      if !reviewed_pr_ids.include?(review.pr_id)
        reviewed_pr_ids.append(review.pr_id)
      end
    end

    relevant_prs = []
    for pr in @pull_requests
      if reviewed_pr_ids.include?(pr.pr_id)
        relevant_prs.append(pr)
      end
    end

    @employee.review_coverage = cal_review_coverage(relevant_prs)
    @employee.response_time = cal_review_response_time(relevant_prs)
    @employee.closing_speed = cal_engagement(relevant_prs,emp_reviews)
    @employee.engagement_score = cal_closing_speed(relevant_prs)

    @employee.save!
  end

  def calculate_and_normalize
    calculate
  
    metric_names = [
      :merge_speed,
      :churn_score,
      :code_quality,
      :review_coverage,
      :response_time,
      :closing_speed,
      :engagement_score,
      :response_to_feedback
    ]
  
    metric_names.each do |metric|
      range = MetricRange.find_by(metric_name: metric)
      if range.nil? || range.min.nil? || range.max.nil?
        @employee[metric] = 0.0
        next
      end
  
      min = range.min.to_f
      max = range.max.to_f
      raw_val = @employee[metric].to_f
      normalized = 0.0
  
      if raw_val.finite? && min.finite? && max.finite?
        normalized = ((raw_val - min) / (max - min)) * 100
      end
  
      if normalized.finite?
        @employee[metric] = [[normalized, 100].min, 0].max
      end
    end
  
    dev_score = 0.0
    rev_score = 0.0
  
    dev_score += 0.15 * (@employee.churn_score.to_f / 100.0)
    dev_score += 0.30 * (@employee.code_quality.to_f / 100.0)
    dev_score += 0.30 * (1 - @employee.merge_speed.to_f / 100.0) if @employee.merge_speed.to_f > 0
    dev_score += 0.25 * (1 - @employee.response_to_feedback.to_f / 100.0) if @employee.response_to_feedback.to_f > 0
  
    rev_score += 0.25 * (@employee.review_coverage.to_f / 100.0)
    rev_score += 0.25 * (@employee.engagement_score.to_f / 100.0)
    rev_score += 0.30 * (1 - @employee.closing_speed.to_f / 100.0) if @employee.closing_speed.to_f > 0
    rev_score += 0.20 * (1 - @employee.response_time.to_f / 100.0) if @employee.response_time.to_f > 0
  
    @employee.dev_score = (dev_score * 100).round(2)
    @employee.rev_score = (rev_score * 100).round(2)
  
    @employee.save!
  end
  
  
  def cal_churn_score
    if @developer_matrices.empty?
      return nil
    end

    pr_ids = []
    @dev_pr.each do |dpr|
      pr_ids.append(dpr.pr_id)
    end

    total_loc = 0
    cnt = 0
    @developer_matrices.each do |mat|
      if pr_ids.include?(mat.pr_id)
        total_loc += mat.LOC
        cnt+=1
      end
    end

    if cnt==0
      return nil
    end

    total_loc.to_f/cnt

  end

  def cal_code_quality
    if @developer_matrices.empty?
      return nil
    end

    pr_ids = []
    cnt=0
    @dev_pr.each do |dpr|
      pr_ids.append(dpr.pr_id)
      cnt += dpr.review_counts.to_i
    end

    total_loc = 0
    @developer_matrices.each do |mat|
      if pr_ids.include?(mat.pr_id)
        total_loc += mat.LOC.to_i
      end
    end

    if cnt==0
      return 0
    end

    total_loc.to_f/cnt
  end

  def cal_merge_speed
    if @dev_pr.empty?
      return nil
    end

    merged_prs = @dev_pr.where.not(pr_merged_at: nil)

    if merged_prs.empty?
      return nil
    end

    total = 0
    merged_prs.each do |pr|
      mat = @developer_matrices.find { |m| m.pr_id == pr.pr_id }
      loc=1
      if mat && mat.LOC != 0
        loc = mat.LOC
      end
      total += (time_diff(pr.pr_merged_at,pr.pr_created_at)/loc)
    end
    total/merged_prs.size.to_f
  end

  def cal_response_to_feedback
    pr_ids = []
    for matrix in @developer_matrices
      pr_ids.append(matrix.pr_id)
    end

    @dev_rev = @reviews.where(pr_id: pr_ids)
    if @dev_rev.empty?
      return nil
    end
    total = 0
    @dev_rev.each do |rev|
      if rev.rev_created_at
        total += time_diff(rev.next_commit_at, rev.rev_created_at)
      end
    end
    total / @dev_rev.size.to_f
  end

  def cal_review_coverage(relevant_prs)
    if relevant_prs.empty?
      return nil
    end
    total_loc = 0
    relevant_prs.each do |pr|
      total_loc += pr.LOC.to_i
    end

    if relevant_prs.size == 0
      return nil
    end

    total_loc / relevant_prs.size.to_f
  end

  def cal_review_response_time(relevant_prs)
    if relevant_prs.empty?
      return nil
    end
    total = 0
    relevant_prs.each do |pr|
      @reviews.each do |rev|
        if rev.pr_id == pr.pr_id && rev.rev_created_at
          loc = 1
          if pr.LOC.to_i != 0
            loc = pr.LOC
          end
          total += time_diff(rev.rev_created_at,pr.pr_created_at)/loc
        end
      end
    end

    if relevant_prs.size == 0
      return nil
    end

    total / relevant_prs.size.to_f
  end

  def cal_engagement(relevant_prs,emp_reviews)
    if emp_reviews.empty?
      return nil
    end
    feedback_cnt = 0
    for rev in emp_reviews
      if rev.next_commit_at
        feedback_cnt+=1
      end
    end

    (emp_reviews.size + feedback_cnt).to_f / relevant_prs.size 

  end

  def cal_closing_speed(relevant_prs)
    if relevant_prs.empty?
      return nil
    end

    total = 0
    cnt = 0

    relevant_prs.each do |pr|
      loc = 1
      if pr.LOC.to_i != 0
        loc = pr.LOC
      end
      if pr.pr_closed_at
        total += time_diff(pr.pr_closed_at , pr.pr_merged_at)/loc
        cnt += 1
      end
    end

    if cnt == 0
      return nil
    end

    total / cnt.to_f
  end

  def time_diff(later, earlier)
    if later.nil? || earlier.nil?
      return 0
    end

    later.to_f - earlier.to_f

  end
end