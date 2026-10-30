class CreateOpportunities < ActiveRecord::Migration[7.2]
  def change
    create_table :opportunities do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :value, precision: 15, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.date :expected_close_on
      t.bigint :account_id, null: false
      t.bigint :funnel_id, null: false
      t.bigint :funnel_stage_id, null: false
      t.bigint :contact_id
      t.bigint :assignee_id

      t.timestamps
    end

    add_index :opportunities, [:funnel_stage_id, :position]
    add_index :opportunities, [:account_id, :status]
    add_index :opportunities, :funnel_id
    add_index :opportunities, :contact_id
    add_index :opportunities, :assignee_id
  end
end
