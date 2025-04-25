class ChangePrIdToBigInt < ActiveRecord::Migration[6.1]
  def change
    change_column :pull_requests, :pr_id, :bigint
  end
end
