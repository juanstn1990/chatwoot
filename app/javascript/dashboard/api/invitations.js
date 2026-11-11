/* global axios */
import ApiClient from './ApiClient';

// Las invitaciones de Invita, vistas desde una conversacion.
class InvitationsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  base(conversationId) {
    return `${this.url}/${conversationId}/invitations`;
  }

  list(conversationId) {
    return axios.get(this.base(conversationId));
  }

  sources(conversationId, q = '') {
    return axios.get(`${this.base(conversationId)}/sources`, { params: { q } });
  }

  search(conversationId, q = '') {
    return axios.get(`${this.base(conversationId)}/search`, { params: { q } });
  }

  create(conversationId, { origin, title }) {
    return axios.post(this.base(conversationId), { origin, title });
  }

  link(conversationId, id, move = false) {
    return axios.post(`${this.base(conversationId)}/${id}/link`, {
      move: move || undefined,
    });
  }

  unlink(conversationId, id) {
    return axios.delete(`${this.base(conversationId)}/${id}/link`);
  }

  startHere(conversationId, id) {
    return axios.post(`${this.base(conversationId)}/${id}/start_here`);
  }

  propose(conversationId, id, { all = false, note = '' } = {}) {
    return axios.post(`${this.base(conversationId)}/${id}/propose`, {
      all: all || undefined,
      note,
    });
  }

  apply(conversationId, id, { changes, until, reopen = false }) {
    return axios.post(`${this.base(conversationId)}/${id}/apply`, {
      changes,
      until,
      reopen: reopen || undefined,
    });
  }
}

export default new InvitationsAPI();
