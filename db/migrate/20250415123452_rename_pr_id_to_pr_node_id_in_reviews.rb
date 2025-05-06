class RenamePrIdToPrNodeIdInReviews < ActiveRecord::Migration[6.1]
  def change
    rename_column :reviews, :pr_id, :pr_node_id
  end
end
