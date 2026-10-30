/* global axios */
import ApiClient from './ApiClient';

class OpportunitiesAPI extends ApiClient {
  constructor() {
    super('opportunities', { accountScoped: true });
  }

  getByFunnel(funnelId) {
    return axios.get(this.url, { params: { funnel_id: funnelId } });
  }

  getByContact(contactId) {
    return axios.get(this.url, { params: { contact_id: contactId } });
  }

  move({ id, funnelStageId, position }) {
    return axios.patch(`${this.url}/${id}/move`, {
      funnel_stage_id: funnelStageId,
      position,
    });
  }
}

export default new OpportunitiesAPI();
