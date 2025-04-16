class CreateDeveloperMatrices < ActiveRecord::Migration[6.1]
  def change
    create_table :developer_matrices do |t|
      t.integer :pr_id
      t.string :github_id
      t.integer :LOC

      t.timestamps
    end
  end
end
