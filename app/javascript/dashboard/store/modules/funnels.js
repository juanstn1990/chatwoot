import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import FunnelsAPI from '../../api/funnels';
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
  getFunnels($state) {
    return $state.records;
  },
  getFunnel: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isFetching: true });
    try {
      const response = await FunnelsAPI.get();
      commit(types.SET_FUNNELS, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, funnel) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isCreating: true });
    try {
      const response = await FunnelsAPI.create({ funnel });
      commit(types.ADD_FUNNEL, response.data.payload);
      return response.data.payload;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...funnel }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      const response = await FunnelsAPI.update(id, { funnel });
      commit(types.EDIT_FUNNEL, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isDeleting: true });
    try {
      await FunnelsAPI.delete(id);
      commit(types.DELETE_FUNNEL, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isDeleting: false });
    }
  },
  createStage: async ({ commit, dispatch }, { funnelId, ...stage }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      await FunnelsAPI.createStage(funnelId, stage);
      await dispatch('get');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
  updateStage: async ({ commit, dispatch }, { funnelId, id, ...stage }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      await FunnelsAPI.updateStage(funnelId, id, stage);
      await dispatch('get');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
  reorderStages: async ({ commit, dispatch }, { funnelId, stages }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      await Promise.all(
        stages.map((stage, index) =>
          FunnelsAPI.updateStage(funnelId, stage.id, { position: index })
        )
      );
      await dispatch('get');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
  deleteStage: async ({ commit, dispatch }, { funnelId, id }) => {
    commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: true });
    try {
      await FunnelsAPI.deleteStage(funnelId, id);
      await dispatch('get');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_FUNNELS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_FUNNELS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_FUNNELS]: MutationHelpers.set,
  [types.ADD_FUNNEL]: MutationHelpers.create,
  [types.EDIT_FUNNEL]: MutationHelpers.update,
  [types.DELETE_FUNNEL]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
