class Api::V1::Accounts::Funnels::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_funnel
  before_action :fetch_stage, only: [:update, :destroy]
  before_action :check_authorization

  def create
    @stage = @funnel.funnel_stages.create!(permitted_params)
  end

  def update
    @stage.update!(permitted_params)
  end

  def destroy
    return render_could_not_create_error(I18n.t('errors.funnel_stages.has_opportunities')) if @stage.opportunities.exists?

    @stage.destroy!
    head :ok
  end

  private

  def permitted_params
    params.require(:funnel_stage).permit(:name, :color, :position, :label_id)
  end

  def fetch_funnel
    @funnel = Current.account.funnels.find(params[:funnel_id])
  end

  def fetch_stage
    @stage = @funnel.funnel_stages.find(params[:id])
  end

  def check_authorization
    authorize(@stage || FunnelStage)
  end
end
