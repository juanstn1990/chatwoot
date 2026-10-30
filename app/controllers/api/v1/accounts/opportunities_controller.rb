class Api::V1::Accounts::OpportunitiesController < Api::V1::Accounts::BaseController
  before_action :fetch_opportunity, only: [:show, :update, :destroy, :move]
  before_action :check_authorization

  def index
    @opportunities = Current.account.opportunities
                                    .includes(:assignee, :funnel_stage, :conversation, contact: :conversations)
                                    .for_funnel(params[:funnel_id])
                                    .for_contact(params[:contact_id])
  end

  def show; end

  def create
    @opportunity = Current.account.opportunities.create!(opportunity_attributes)
  end

  def update
    @opportunity.update!(opportunity_attributes)
  end

  def move
    @opportunity.move_to(target_stage, params.require(:position).to_i)
  end

  def destroy
    @opportunity.destroy!
    head :ok
  end

  private

  def permitted_params
    params.require(:opportunity).permit(
      :name, :description, :value, :status, :expected_close_on,
      :funnel_stage_id, :contact_id, :assignee_id, :conversation_display_id
    )
  end

  # El frontend enruta por display_id, no por la clave primaria de la conversacion.
  def opportunity_attributes
    attributes = permitted_params.except(:conversation_display_id)
    display_id = permitted_params[:conversation_display_id]
    return attributes if display_id.blank?

    attributes.merge(conversation_id: Current.account.conversations.find_by!(display_id: display_id).id)
  end

  def target_stage
    @opportunity.funnel.funnel_stages.find(params.require(:funnel_stage_id))
  end

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:id])
  end

  def check_authorization
    authorize(@opportunity || Opportunity)
  end
end
