class ChangeReviewsTableStructure < ActiveRecord::Migration[6.1]
  def change
    change_column :reviews, :review_id, :integer
    remove_column :reviews, :is_resolved, :boolean
    add_column :reviews, :reaction_count, :integer
    add_column :reviews, :review_node_id, :string
    rename_column :reviews, :submitted_at, :next_commit_at
  end
end
