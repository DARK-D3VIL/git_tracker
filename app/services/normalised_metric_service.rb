class NormalisedMetricService
  def initialize(employees, start_date, end_date, status)
    @employees = employees
    @pull_requests = PullRequest.where(pr_created_at: start_date..end_date)
    @reviews = Review.where(rev_created_at: start_date..end_date)
    if status == "closed"
      @pull_requests = @pull_requests.where(status: status)
    end
    @developer_matrices = DeveloperMatrix
  end

  def normalize
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

    for emp in @employees
      calculator = MetricCalculate.new(emp, @reviews, @developer_matrices, @pull_requests)
      calculator.calculate
    end

    update_min_max_values(metric_names)


    normalize_metrices(metric_names)

    calculate_final_scores
  end

  def update_min_max_values(metric_names)
    min_max = {}
    metric_names.each do |metric|
      values = []
      for emp in @employees
        values.append(emp[metric].to_f)
      end
      min_value = values.select { |v| v > 0 }.min
      max_value = values.max

      range = MetricRange.find_or_initialize_by(metric_name: metric.to_s)

      if min_value && (range.min.nil? || min_value < range.min)
        range.min = min_value
      end

      if max_value && (range.max.nil? || max_value > range.max)
        range.max = max_value
      end

      range.save!

      min_max[metric] = [min_value,max_value]
    end

    min_max
  end

  def normalize_metrices(metric_names)
    @employees.each do |emp|
      metric_names.each do |metric|
        range = MetricRange.find_by(metric_name: metric.to_s)
        
        if range.nil? || range.min.nil? || range.max.nil?
          emp[metric] = 0
          next
        end
    
        min = range.min.to_f
        max = range.max.to_f
        raw_val = emp[metric].to_f
        normalized = 0.0
  
        if max > min && raw_val.finite? && min.finite? && max.finite?
          normalized = ((raw_val - min) / (max - min)) * 100
        end

        emp[metric] = [[normalized, 100].min, 0].max if normalized.finite?
      end
    end
  end    

  def calculate_final_scores
    for emp in @employees
      dev_score = 0.0
      rev_score = 0.0

      dev_score += 0.15 * (emp.churn_score / 100.0)
      dev_score += 0.30 * (emp.code_quality / 100.0)
      if emp.merge_speed > 0
        dev_score += 0.30 * (1 - emp.merge_speed / 100.0)
      end
      if emp.response_to_feedback > 0
        dev_score += 0.25 * (1 - emp.response_to_feedback / 100.0)
      end

      rev_score += 0.25 * (emp.review_coverage / 100.0)
      rev_score += 0.25 * (emp.engagement_score / 100.0)
      if emp.closing_speed > 0
        rev_score += 0.30 * (1 - emp.closing_speed / 100.0)
      end
      if emp.response_time > 0
        rev_score += 0.20 * (1 - emp.response_time / 100.0)
      end

      emp.dev_score = dev_score * 100
      emp.rev_score = rev_score * 100
      emp.save!
    end
  end
end