class ChangeDefaultToResponseToFeedback < ActiveRecord::Migration[6.1]
  def change
    change_column_default :employees, :response_to_feedback, from: nil, to: 0.0
  end
end
