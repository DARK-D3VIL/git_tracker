class ChangeAllidstoBigInt < ActiveRecord::Migration[6.1]
  def change
    change_column :developer_matrices, :pr_id, :bigint
    change_column :developer_matrices, :github_id, :bigint, using: 'github_id::bigint'
    change_column :employees, :github_id, :bigint, using: 'github_id::bigint'
    change_column :reviews, :pr_id, :bigint
    change_column :reviews, :github_id, :bigint, using: 'github_id::bigint'
  end
end
