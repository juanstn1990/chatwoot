import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import OpportunitiesAPI from '../../api/opportunities';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getOpportunities($state) {
    return $state.records;
  },
  getOpportunitiesByStage: $state => stageId => {
    return $state.records
      .filter(record => record.funnel_stage_id === stageId)
      .sort((a, b) => a.position - b.position);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }, funnelId) => {
    commit(types.SET_OPPORTUNITIES_UI_FLAG, { isFetching: true });
    try {
      const response = await OpportunitiesAPI.getByFunnel(funnelId);
      commit(types.SET_OPPORTUNITIES, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_OPPORTUNITIES_UI_FLAG, { isFetching: false });
    }
  },
  getByContact: async (_, contactId) => {
    try {
      const response = await OpportunitiesAPI.getByContact(contactId);
      return response.data.payload;
    } catch (error) {
      return throwErrorMessage(error);
    }
  },
  create: async ({ commit }, opportunity) => {
    commit(types.SET_OPPORTUNITIES_UI_FLAG, { isCreating: true });
    try {
      const response = await OpportunitiesAPI.create({ opportunity });
      commit(types.ADD_OPPORTUNITY, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_OPPORTUNITIES_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...opportunity }) => {
    commit(types.SET_OPPORTUNITIES_UI_FLAG, { isUpdating: true });
    try {
      const response = await OpportunitiesAPI.update(id, { opportunity });
      commit(types.EDIT_OPPORTUNITY, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_OPPORTUNITIES_UI_FLAG, { isUpdating: false });
    }
  },
  move: async ({ commit, dispatch }, { id, funnelStageId, position, funnelId }) => {
    try {
      const response = await OpportunitiesAPI.move({ id, funnelStageId, position });
      commit(types.EDIT_OPPORTUNITY, response.data.payload);
      if (funnelId) await dispatch('get', funnelId);
    } catch (error) {
      throwErrorMessage(error);
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_OPPORTUNITIES_UI_FLAG, { isDeleting: true });
    try {
      await OpportunitiesAPI.delete(id);
      commit(types.DELETE_OPPORTUNITY, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_OPPORTUNITIES_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_OPPORTUNITIES_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_OPPORTUNITIES]: MutationHelpers.set,
  [types.ADD_OPPORTUNITY]: MutationHelpers.create,
  [types.EDIT_OPPORTUNITY]: MutationHelpers.update,
  [types.DELETE_OPPORTUNITY]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
