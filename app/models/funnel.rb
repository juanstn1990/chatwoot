# == Schema Information
#
# Table name: funnels
#
#  id          :bigint           not null, primary key
#  currency    :string           default("USD"), not null
#  description :text
#  name        :string           not null
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_funnels_on_account_id_and_position  (account_id,position)
#
class Funnel < ApplicationRecord
  DEFAULT_STAGES = [
    { name: 'Interesado', color: '#3b82f6' },
    { name: 'En curso', color: '#f59e0b' },
    { name: 'Terminado', color: '#10b981' }
  ].freeze

  belongs_to :account
  has_many :funnel_stages, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :funnel
  has_many :opportunities, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :currency, presence: true

  after_create :create_default_stages

  default_scope { order(:position, :id) }

  def total_value
    opportunities.open.sum(:value)
  end

  private

  def create_default_stages
    DEFAULT_STAGES.each_with_index do |stage, index|
      funnel_stages.create!(name: stage[:name], color: stage[:color], position: index)
    end
  end
end
