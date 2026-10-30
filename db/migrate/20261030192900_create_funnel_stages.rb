class CreateFunnelStages < ActiveRecord::Migration[7.2]
  def change
    create_table :funnel_stages do |t|
      t.string :name, null: false
      t.string :color, null: false, default: '#1f93ff'
      t.integer :position, null: false, default: 0
      t.bigint :funnel_id, null: false

      t.timestamps
    end

    add_index :funnel_stages, [:funnel_id, :position]
  end
end
