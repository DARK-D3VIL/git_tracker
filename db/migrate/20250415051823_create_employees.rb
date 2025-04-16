class CreateEmployees < ActiveRecord::Migration[6.1]
  def change
    create_table :employees do |t|
      t.string :github_id
      t.string :name
      t.float :dev_score
      t.float :rev_score

      t.timestamps
    end
  end
end
