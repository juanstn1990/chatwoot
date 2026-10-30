# Coloca el contacto de una conversacion en la etapa del Kanban cuya etiqueta
# asociada este aplicada en esa conversacion. Solo actuan las etapas que tienen
# una etiqueta configurada.
class Kanban::LabelSyncService
  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    return if contact.blank? || stage.blank?
    return if opportunity.funnel_stage_id == stage.id

    opportunity.move_to(stage, 0, sync_labels: false)
  end

  private

  attr_reader :conversation

  def account
    @account ||= conversation.account
  end

  def contact
    @contact ||= conversation.contact
  end

  # La etapa mas avanzada del embudo entre las etiquetas aplicadas, para que
  # tener varias etiquetas no devuelva el trato al principio.
  def stage
    @stage ||= FunnelStage.joins(:label, :funnel)
                          .where(funnels: { account_id: account.id })
                          .where(labels: { title: conversation.label_list })
                          .order(position: :desc)
                          .first
  end

  def opportunity
    @opportunity ||= existing_opportunity || create_opportunity
  end

  def existing_opportunity
    account.opportunities.find_by(conversation_id: conversation.id) ||
      account.opportunities.find_by(contact_id: contact.id, funnel_id: stage.funnel_id)
  end

  def create_opportunity
    account.opportunities.create!(
      name: contact.name.presence || "##{conversation.display_id}",
      funnel_stage: stage,
      contact: contact,
      conversation: conversation
    )
  end
end
