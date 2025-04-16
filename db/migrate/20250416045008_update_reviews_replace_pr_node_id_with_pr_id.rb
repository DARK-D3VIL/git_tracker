class UpdateReviewsReplacePrNodeIdWithPrId < ActiveRecord::Migration[6.1]
  def change
    remove_column :reviews, :pr_node_id, :string
    add_column :reviews, :pr_id, :integer
  end
end
