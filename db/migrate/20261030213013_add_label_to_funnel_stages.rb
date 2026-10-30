class AddLabelToFunnelStages < ActiveRecord::Migration[7.2]
  def change
    add_column :funnel_stages, :label_id, :bigint
    add_index :funnel_stages, :label_id
  end
end
