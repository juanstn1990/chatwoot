class Api::V1::Accounts::FunnelsController < Api::V1::Accounts::BaseController
  before_action :fetch_funnel, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @funnels = Current.account.funnels.includes(funnel_stages: :label)
  end

  def show; end

  def create
    @funnel = Current.account.funnels.create!(permitted_params)
  end

  def update
    @funnel.update!(permitted_params)
  end

  def destroy
    @funnel.destroy!
    head :ok
  end

  private

  def permitted_params
    params.require(:funnel).permit(:name, :description, :currency, :position)
  end

  def fetch_funnel
    @funnel = Current.account.funnels.find(params[:id])
  end

  def check_authorization
    authorize(@funnel || Funnel)
  end
end
