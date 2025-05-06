class ChangeMetricDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :employees, :merge_speed, from: nil, to: 0.0
    change_column_default :employees, :churn_score, from: nil, to: 0.0
    change_column_default :employees, :code_quality, from: nil, to: 0.0
    change_column_default :employees, :review_coverage, from: nil, to: 0.0
    change_column_default :employees, :response_time, from: nil, to: 0.0
    change_column_default :employees, :closing_speed, from: nil, to: 0.0
    change_column_default :employees, :engagement_score, from: nil, to: 0.0
  end
end
