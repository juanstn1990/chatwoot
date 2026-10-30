class KanbanListener < BaseListener
  def conversation_updated(event)
    conversation, = extract_conversation_and_account(event)
    Kanban::LabelSyncService.new(conversation).perform
  end

  def conversation_created(event)
    conversation_updated(event)
  end
end
