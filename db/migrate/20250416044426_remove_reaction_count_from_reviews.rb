class RemoveReactionCountFromReviews < ActiveRecord::Migration[6.1]
  def change
    remove_column :reviews, :reaction_count, :integer
  end
end
