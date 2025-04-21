class MetricCalculate
  def initialize(employee,reviews,developer_matrices,pull_requests)
    @employee = employee
    @reviews = reviews
    @developer_matrices = developer_matrices.where(github_id: employee.github_id)
    @pull_requests = pull_requests

    pr_ids = []
    for matrix in @developer_matrices
      pr_ids.append(matrix.pr_id)
    end

    @dev_pr = pull_requests.where(pr_id: pr_ids)
  end

  def calculate
    @merge_speed = cal_merge_speed
    @churn_score = cal_churn_score
    @code_quality = cal_code_quality
    @response_to_feedback = cal_response_to_feedback
    @employee.dev_score = cal_dev_met

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


    @review_coverage = cal_review_coverage(relevant_prs)
    @review_response_time = cal_review_response_time(relevant_prs)
    @engagement = cal_engagement(relevant_prs,emp_reviews)
    @closing_speed = cal_closing_speed(relevant_prs)
    @employee.rev_score = cal_rev_met
    @employee.save!

    {
      "dev_score" => @employee.dev_score,
      "rev_score" => @employee.rev_score,
      "merge_speed" => @merge_speed,
      "churn_score" => @churn_score,
      "code_quality" => @code_quality,
      "review_coverage" => @review_coverage,
      "response_time" => @review_response_time,
      "closing_speed" => @closing_speed,
      "engagement_score" => @engagement
    }
  end

  def cal_dev_met
    if @dev_pr.empty?
      return 0
    end

    res = 0.30 * @code_quality + 0.15 * @churn_score
     if @merge_speed > 0
      res += 0.30 * (100 - @merge_speed/10000)
     end
     if @response_to_feedback > 0
      res += 0.25 * (100 - @response_to_feedback/10000)
     end

     res
  end

  def cal_churn_score
    if @developer_matrices.empty?
      return 0
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
      return 0
    end

    total_loc.to_f/cnt

  end

  def cal_code_quality
    if @developer_matrices.empty?
      return 0
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
    merged_prs = @dev_pr.where("pr_merged_at IS NOT NULL")
    if merged_prs.empty?
      return 0
    end

    total = 0
    merged_prs.each do |pr|
      mat = @developer_matrices.find { |m| m.pr_id == pr.pr_id }
      loc=1
      if mat && mat.LOC != 0
        loc = mat&.LOC
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
      return 0
    end
    total = 0
    @dev_rev.each do |rev|
      if rev.rev_created_at
        total += time_diff(rev.next_commit_at, rev.rev_created_at)
      end
    end
    total / @dev_rev.size.to_f
  end

  def cal_rev_met
    res = 0.25 * @review_coverage + 0.25 * @engagement
    if @closing_speed > 0
      res += 0.30 * (100 - @closing_speed/100)
    end
    if @review_response_time > 0
      res += 0.20 * (100 - @review_response_time/100)
    end

    res
  end

  def cal_review_coverage(relevant_prs)
    if relevant_prs.empty?
      return 0
    end
    total_loc = 0
    relevant_prs.each do |pr|
      total_loc += pr.LOC.to_i
    end

    if relevant_prs.size == 0
      return 0
    end

    total_loc / relevant_prs.size.to_f
  end

  def cal_review_response_time(relevant_prs)
    if relevant_prs.empty?
      return 0
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
      return 0
    end

    total / relevant_prs.size.to_f
  end

  def cal_engagement(relevant_prs,emp_reviews)
    if emp_reviews.empty?
      return 0
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
      return 0
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
      return 0
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