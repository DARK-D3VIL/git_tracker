class ChangePrNodeIdAndReviewIdToStringInReviews < ActiveRecord::Migration[6.1]
  def change
    change_column :reviews, :pr_node_id, :string
    change_column :reviews, :review_id, :string
  end
end
