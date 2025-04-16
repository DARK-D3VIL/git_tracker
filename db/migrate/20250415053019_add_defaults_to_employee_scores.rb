class AddDefaultsToEmployeeScores < ActiveRecord::Migration[6.1]
  def change
    change_column_default :employees, :dev_score, from: nil, to: 0.0
    change_column_default :employees, :rev_score, from: nil, to: 0.0
  end
end
