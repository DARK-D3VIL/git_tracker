class CreatePullRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :pull_requests do |t|
      t.integer :pr_id
      t.datetime :pr_created_at
      t.datetime :pr_closed_at
      t.datetime :pr_merged_at
      t.string :status
      t.integer :LOC
      t.integer :review_counts

      t.timestamps
    end
  end
end
