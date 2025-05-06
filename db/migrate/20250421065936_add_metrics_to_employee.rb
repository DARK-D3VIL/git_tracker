class AddMetricsToEmployee < ActiveRecord::Migration[6.1]
  def change
    add_column :employees, :merge_speed, :float, dafault: 0.0
    add_column :employees, :churn_score, :float, dafault: 0.0
    add_column :employees, :code_quality, :float, dafault: 0.0
    add_column :employees, :review_coverage, :float, dafault: 0.0
    add_column :employees, :response_time, :float, dafault: 0.0
    add_column :employees, :closing_speed, :float, dafault: 0.0
    add_column :employees, :engagement_score, :float, dafault: 0.0
  end
end
