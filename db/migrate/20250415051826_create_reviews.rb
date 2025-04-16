class CreateReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :reviews do |t|
      t.string :github_id
      t.integer :review_id
      t.integer :pr_id
      t.datetime :rev_created_at
      t.boolean :is_resolved

      t.timestamps
    end
  end
end
