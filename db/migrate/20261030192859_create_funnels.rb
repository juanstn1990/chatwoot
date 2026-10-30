class CreateFunnels < ActiveRecord::Migration[7.2]
  def change
    create_table :funnels do |t|
      t.string :name, null: false
      t.text :description
      t.string :currency, null: false, default: 'USD'
      t.integer :position, null: false, default: 0
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :funnels, [:account_id, :position]
  end
end
