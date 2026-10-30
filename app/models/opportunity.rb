# == Schema Information
#
# Table name: opportunities
#
#  id                :bigint           not null, primary key
#  description       :text
#  expected_close_on :date
#  name              :string           not null
#  position          :integer          default(0), not null
#  status            :integer          default("open"), not null
#  value             :decimal(15, 2)   default(0.0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assignee_id       :bigint
#  contact_id        :bigint
#  conversation_id   :bigint
#  funnel_id         :bigint           not null
#  funnel_stage_id   :bigint           not null
#
# Indexes
#
#  index_opportunities_on_account_id_and_status         (account_id,status)
#  index_opportunities_on_assignee_id                   (assignee_id)
#  index_opportunities_on_contact_id                    (contact_id)
#  index_opportunities_on_conversation_id               (conversation_id)
#  index_opportunities_on_funnel_id                     (funnel_id)
#  index_opportunities_on_funnel_stage_id_and_position  (funnel_stage_id,position)
#
class Opportunity < ApplicationRecord
  belongs_to :account
  belongs_to :funnel
  belongs_to :funnel_stage
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true
  belongs_to :assignee, class_name: 'User', optional: true

  enum status: { open: 0, won: 1, lost: 2 }

  validates :name, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validate :stage_belongs_to_funnel

  before_validation :set_funnel_from_stage
  before_create :set_position

  scope :for_funnel, ->(funnel_id) { where(funnel_id: funnel_id) if funnel_id.present? }
  scope :for_contact, ->(contact_id) { where(contact_id: contact_id) if contact_id.present? }

  # La conversacion desde la que nacio la oportunidad; si no hay, la mas
  # reciente del contacto, para poder retomar el hilo desde el tablero.
  def conversation_to_resume
    conversation || contact&.conversations&.order(last_activity_at: :desc)&.first
  end

  def move_to(stage, new_position, sync_labels: true)
    transaction do
      update!(funnel_stage: stage, position: new_position)
      stage.opportunities.where.not(id: id).where(position: new_position..).find_each do |opportunity|
        opportunity.update_column(:position, opportunity.position + 1)
      end
    end

    sync_conversation_labels if sync_labels
  end

  # Mantiene la etiqueta de la conversacion en linea con la etapa del tablero,
  # para que arrastrar una tarjeta reetiquete la conversacion.
  def sync_conversation_labels
    return if conversation.blank?

    stage_labels = funnel.funnel_stages.includes(:label).filter_map { |stage| stage.label&.title }
    return if stage_labels.empty?

    labels = conversation.label_list - stage_labels
    labels << funnel_stage.label.title if funnel_stage.label
    conversation.update_labels(labels.uniq)
  end

  private

  def set_funnel_from_stage
    self.funnel_id = funnel_stage.funnel_id if funnel_stage.present?
  end

  def stage_belongs_to_funnel
    return if funnel_stage.blank? || funnel.blank?
    return if funnel_stage.funnel_id == funnel_id

    errors.add(:funnel_stage, I18n.t('errors.opportunities.stage_mismatch'))
  end

  def set_position
    self.position = (funnel_stage.opportunities.maximum(:position) || -1) + 1
  end
end
