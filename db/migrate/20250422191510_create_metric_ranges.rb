class CreateMetricRanges < ActiveRecord::Migration[6.1]
  def change
    create_table :metric_ranges do |t|
      t.string :metric_name
      t.float :min
      t.float :max

      t.timestamps
    end
  end
end
