class AddConversationToOpportunities < ActiveRecord::Migration[7.2]
  def change
    add_column :opportunities, :conversation_id, :bigint
    add_index :opportunities, :conversation_id
  end
end
