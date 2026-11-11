<script setup>
import { onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import InvitationsAPI from 'dashboard/api/invitations';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import InvitaSourceDialog from './InvitaSourceDialog.vue';
import InvitaProposalDialog from './InvitaProposalDialog.vue';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const { t } = useI18n();

const invitations = ref([]);
const isLoading = ref(false);
const loadError = ref('');
const sourceDialogRef = ref(null);
const proposalDialogRef = ref(null);

const errorOf = error =>
  error?.response?.data?.error || error?.message || t('INVITA.ERROR');

const fetchInvitations = async () => {
  isLoading.value = true;
  loadError.value = '';
  try {
    const { data } = await InvitationsAPI.list(props.conversationId);
    invitations.value = data.invitaciones ?? [];
  } catch (error) {
    invitations.value = [];
    loadError.value = errorOf(error);
  } finally {
    isLoading.value = false;
  }
};

const copyLink = async link => {
  await copyTextToClipboard(link);
  useAlert(t('INVITA.COPIED'));
};

const unlink = async invitation => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('INVITA.UNLINK_CONFIRM', { title: invitation.titulo })))
    return;
  try {
    await InvitationsAPI.unlink(props.conversationId, invitation.id);
    await fetchInvitations();
  } catch (error) {
    useAlert(errorOf(error));
  }
};

const startHere = async invitation => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('INVITA.START_HERE_CONFIRM'))) return;
  try {
    await InvitationsAPI.startHere(props.conversationId, invitation.id);
    useAlert(t('INVITA.START_HERE_DONE'));
    await fetchInvitations();
  } catch (error) {
    useAlert(errorOf(error));
  }
};

// Recien creada, lo natural es llenarla con lo que ya se dijo en el chat.
const onCreated = async ({ invitation, fill }) => {
  await fetchInvitations();
  if (fill) proposalDialogRef.value.open(invitation, { all: true });
};

watch(() => props.conversationId, fetchInvitations);
onMounted(fetchInvitations);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div v-if="isLoading" class="flex justify-center py-2">
      <Spinner :size="20" />
    </div>

    <p v-else-if="loadError" class="text-sm break-words text-n-ruby-11">
      {{ loadError }}
    </p>

    <template v-else>
      <div
        v-for="invitation in invitations"
        :key="invitation.id"
        class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak"
      >
        <div class="flex items-start justify-between gap-2">
          <span class="text-sm font-medium text-n-slate-12">
            {{ invitation.titulo }}
          </span>
          <span
            class="px-1.5 py-0.5 text-xs rounded shrink-0 bg-n-alpha-2 text-n-slate-11"
          >
            {{ invitation.estadoEtiqueta }}
          </span>
        </div>
        <span class="text-xs text-n-slate-11">
          {{ `${invitation.diseno} · ${invitation.pago}` }}
        </span>

        <Button
          size="sm"
          :label="t('INVITA.APPLY_CHANGES')"
          @click="proposalDialogRef.open(invitation)"
        />

        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
          <a
            :href="invitation.editor"
            target="_blank"
            rel="noopener noreferrer"
            class="text-n-blue-11 hover:underline"
          >
            {{ t('INVITA.OPEN_EDITOR') }}
          </a>
          <a
            v-if="invitation.enlace"
            :href="invitation.enlace"
            target="_blank"
            rel="noopener noreferrer"
            class="text-n-blue-11 hover:underline"
          >
            {{ t('INVITA.VIEW') }}
          </a>
          <button
            v-if="invitation.multimedia"
            type="button"
            class="text-n-blue-11 hover:underline"
            @click="copyLink(invitation.multimedia)"
          >
            {{ t('INVITA.COPY_MEDIA_LINK') }}
          </button>
          <button
            type="button"
            class="text-n-slate-10 hover:underline"
            :title="t('INVITA.START_HERE_HINT')"
            @click="startHere(invitation)"
          >
            {{ t('INVITA.START_HERE') }}
          </button>
          <button
            type="button"
            class="text-n-slate-10 hover:underline"
            @click="unlink(invitation)"
          >
            {{ t('INVITA.UNLINK') }}
          </button>
        </div>
      </div>

      <p v-if="!invitations.length" class="text-sm text-n-slate-11">
        {{ t('INVITA.EMPTY') }}
      </p>

      <div class="flex gap-2">
        <Button
          variant="outline"
          color="slate"
          size="sm"
          :label="t('INVITA.CREATE')"
          @click="sourceDialogRef.open('create')"
        />
        <Button
          variant="ghost"
          color="slate"
          size="sm"
          :label="t('INVITA.LINK_EXISTING')"
          @click="sourceDialogRef.open('link')"
        />
      </div>
    </template>

    <InvitaSourceDialog
      ref="sourceDialogRef"
      :conversation-id="conversationId"
      @created="onCreated"
      @linked="fetchInvitations"
    />
    <InvitaProposalDialog
      ref="proposalDialogRef"
      :conversation-id="conversationId"
      @applied="fetchInvitations"
    />
  </div>
</template>
