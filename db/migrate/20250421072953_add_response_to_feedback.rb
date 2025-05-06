class AddResponseToFeedback < ActiveRecord::Migration[6.1]
  def change
    add_column :employees, :response_to_feedback, :float, dafault: 0.0
  end
end
