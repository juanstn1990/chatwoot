# == Schema Information
#
# Table name: funnel_stages
#
#  id         :bigint           not null, primary key
#  color      :string           default("#1f93ff"), not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  funnel_id  :bigint           not null
#  label_id   :bigint
#
# Indexes
#
#  index_funnel_stages_on_funnel_id_and_position  (funnel_id,position)
#  index_funnel_stages_on_label_id                (label_id)
#
class FunnelStage < ApplicationRecord
  belongs_to :funnel
  belongs_to :label, optional: true
  has_many :opportunities, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :funnel_stage

  validates :name, presence: true
  validates :color, presence: true
  validates :label_id, uniqueness: { scope: :funnel_id }, allow_nil: true

  default_scope { order(:position, :id) }

  def total_value
    opportunities.open.sum(:value)
  end
end
