class NormalisedMetricService
  def initialize(employees, reviews, developer_matrices, pull_requests)
    @employees = employees
    @reviews = reviews
    @developer_matrices = developer_matrices
    @pull_requests = pull_requests
  end

  def normalize
    for emp in @employees
      calculator = MetricCalculate.new(emp, @reviews, @developer_matrices, @pull_requests)
      calculator.calculate
    end

    min_max_values = get_min_max_values

    normalize_metrices(min_max_values)

    calculate_final_scores
  end

  def get_min_max_values
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

    min_max = {}
    metric_names.each do |metric|
      values = []
      for emp in @employees
        values.append(emp[metric].to_f)
      end
      min_value = values.min
      max_value = values.max

      min_max[metric] = [min_value,max_value]
    end

    min_max
  end

  def normalize_metrices(min_max)
    for emp in @employees
      for metric in  min_max.keys
        min = min_max[metric][0]
        max = min_max[metric][1]
        raw_val = emp[metric].to_f
        normalized = 0.0

        if max > min
          normalized = ((raw_val - min) / (max - min)) * 100
        end

        emp[metric] = normalized
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