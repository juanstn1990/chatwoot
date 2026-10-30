/* global axios */
import ApiClient from './ApiClient';

class FunnelsAPI extends ApiClient {
  constructor() {
    super('funnels', { accountScoped: true });
  }

  createStage(funnelId, data) {
    return axios.post(`${this.url}/${funnelId}/stages`, { funnel_stage: data });
  }

  updateStage(funnelId, stageId, data) {
    return axios.patch(`${this.url}/${funnelId}/stages/${stageId}`, {
      funnel_stage: data,
    });
  }

  deleteStage(funnelId, stageId) {
    return axios.delete(`${this.url}/${funnelId}/stages/${stageId}`);
  }
}

export default new FunnelsAPI();
