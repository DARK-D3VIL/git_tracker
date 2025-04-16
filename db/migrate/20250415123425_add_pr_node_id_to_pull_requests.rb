class AddPrNodeIdToPullRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :pull_requests, :pr_node_id, :string
  end
end
