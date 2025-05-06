class AddSubmittedAtToReviews < ActiveRecord::Migration[6.1]
  def change
    add_column :reviews, :submitted_at, :datetime
  end
end
