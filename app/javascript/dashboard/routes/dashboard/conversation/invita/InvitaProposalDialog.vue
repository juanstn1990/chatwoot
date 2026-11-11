<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import InvitationsAPI from 'dashboard/api/invitations';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

// Lo que el cliente pidio en el chat, pasado a limpio: se revisa, se corrige
// y solo lo que queda marcado se escribe en la invitacion.
const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const emit = defineEmits(['applied']);

const { t } = useI18n();

const dialogRef = ref(null);
const invitation = ref(null);
const proposal = ref(null);
const changes = ref([]);
const note = ref('');
const readAll = ref(false);
const isReading = ref(false);
const isApplying = ref(false);
const errorMessage = ref('');

const selectedChanges = computed(() =>
  changes.value.filter(change => change.selected)
);

const isEmpty = computed(
  () =>
    proposal.value &&
    !changes.value.length &&
    !proposal.value.dudas.length &&
    !proposal.value.otros.length &&
    !proposal.value.faltantes.length
);

const confirmLabel = computed(() =>
  selectedChanges.value.length
    ? t('INVITA.PROPOSAL.APPLY', { count: selectedChanges.value.length })
    : t('INVITA.PROPOSAL.MARK_REVIEWED')
);

const errorOf = error =>
  error?.response?.data?.error || error?.message || t('INVITA.ERROR');

const shown = value =>
  value === '' || value === null || value === undefined
    ? t('INVITA.PROPOSAL.EMPTY_VALUE')
    : String(value);

const read = async () => {
  isReading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await InvitationsAPI.propose(
      props.conversationId,
      invitation.value.id,
      { all: readAll.value, note: note.value }
    );
    proposal.value = data;
    // Lo que no encaja en la invitacion llega marcado y sin seleccionar.
    changes.value = (data.cambios ?? []).map(change => ({
      ...change,
      valor: String(change.valor ?? ''),
      selected: !change.problema,
    }));
  } catch (error) {
    proposal.value = null;
    changes.value = [];
    errorMessage.value = errorOf(error);
  } finally {
    isReading.value = false;
  }
};

const open = (nextInvitation, { all = false } = {}) => {
  invitation.value = nextInvitation;
  proposal.value = null;
  changes.value = [];
  note.value = '';
  readAll.value = all;
  errorMessage.value = '';
  dialogRef.value.open();
  read();
};

const apply = async (reopen = false) => {
  isApplying.value = true;
  errorMessage.value = '';
  try {
    await InvitationsAPI.apply(props.conversationId, invitation.value.id, {
      changes: selectedChanges.value.map(change => ({
        section: change.seccion,
        field: change.campo,
        label: change.etiqueta,
        value: change.valor,
      })),
      until: proposal.value?.hasta,
      reopen,
    });
    useAlert(
      selectedChanges.value.length
        ? t('INVITA.PROPOSAL.APPLIED')
        : t('INVITA.PROPOSAL.REVIEWED')
    );
    emit('applied');
    dialogRef.value.close();
  } catch (error) {
    // Entregada: reabrirla es una decision, se pregunta antes.
    if (error?.response?.data?.entregada && !reopen) {
      // eslint-disable-next-line no-alert
      if (window.confirm(t('INVITA.PROPOSAL.REOPEN_CONFIRM'))) {
        await apply(true);
        return;
      }
    }
    errorMessage.value = errorOf(error);
  } finally {
    isApplying.value = false;
  }
};

const useReply = () => {
  emitter.emit(
    BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
    proposal.value.mensajeParaCliente
  );
  useAlert(t('INVITA.PROPOSAL.REPLY_INSERTED'));
};

const copyReply = async () => {
  await copyTextToClipboard(proposal.value.mensajeParaCliente);
  useAlert(t('INVITA.COPIED'));
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    overflow-y-auto
    :title="t('INVITA.PROPOSAL.TITLE', { title: invitation?.titulo })"
    :confirm-button-label="confirmLabel"
    :cancel-button-label="t('INVITA.CANCEL')"
    :disable-confirm-button="isReading || !proposal"
    :is-loading="isApplying"
    @confirm="apply()"
  >
    <div class="flex flex-col gap-5">
      <div v-if="isReading" class="flex flex-col items-center gap-2 py-8">
        <Spinner :size="24" />
        <span class="text-sm text-n-slate-11">
          {{ t('INVITA.PROPOSAL.READING') }}
        </span>
      </div>

      <template v-else-if="proposal">
        <p
          v-if="proposal.aviso"
          class="p-3 text-sm rounded-lg bg-n-amber-3 text-n-amber-11"
        >
          {{ proposal.aviso }}
        </p>

        <p v-if="isEmpty" class="py-4 text-sm text-center text-n-slate-11">
          {{ t('INVITA.PROPOSAL.NOTHING') }}
        </p>

        <section v-if="changes.length" class="flex flex-col gap-2">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('INVITA.PROPOSAL.CHANGES') }}
          </h4>
          <label
            v-for="(change, index) in changes"
            :key="`${change.seccion}-${change.campo}-${index}`"
            class="flex items-start gap-3 p-3 border rounded-lg border-n-weak"
          >
            <input v-model="change.selected" type="checkbox" class="mt-1" />
            <span class="flex flex-col flex-1 min-w-0 gap-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{ change.etiqueta }}
              </span>
              <span class="text-xs line-through break-words text-n-slate-10">
                {{ shown(change.actual) }}
              </span>
              <textarea
                v-model="change.valor"
                rows="1"
                class="w-full px-2 py-1 text-sm border rounded-md resize-y border-n-weak bg-n-alpha-black2 text-n-slate-12"
              />
              <span class="text-xs text-n-slate-11">{{ change.motivo }}</span>
              <span v-if="change.problema" class="text-xs text-n-ruby-11">
                {{ change.problema }}
              </span>
            </span>
          </label>
        </section>

        <section v-if="proposal.dudas.length" class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('INVITA.PROPOSAL.DOUBTS') }}
          </h4>
          <ul class="text-sm list-disc ltr:pl-5 rtl:pr-5 text-n-slate-11">
            <li v-for="(doubt, index) in proposal.dudas" :key="index">
              {{ doubt.pregunta }}
            </li>
          </ul>
        </section>

        <section v-if="proposal.otros.length" class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('INVITA.PROPOSAL.OTHERS') }}
          </h4>
          <ul class="text-sm list-disc ltr:pl-5 rtl:pr-5 text-n-slate-11">
            <li v-for="(other, index) in proposal.otros" :key="index">
              {{ other.pedido }}
            </li>
          </ul>
        </section>

        <section v-if="proposal.faltantes.length" class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('INVITA.PROPOSAL.MISSING') }}
          </h4>
          <p class="text-sm text-n-slate-11">
            {{ proposal.faltantes.map(item => item.etiqueta).join(' · ') }}
          </p>
        </section>

        <section
          v-if="proposal.mensajeParaCliente"
          class="flex flex-col gap-2 p-3 rounded-lg bg-n-alpha-2"
        >
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('INVITA.PROPOSAL.REPLY') }}
          </h4>
          <p class="text-sm whitespace-pre-wrap text-n-slate-12">
            {{ proposal.mensajeParaCliente }}
          </p>
          <div class="flex gap-2">
            <Button
              size="xs"
              variant="outline"
              color="slate"
              :label="t('INVITA.PROPOSAL.REPLY_USE')"
              @click="useReply"
            />
            <Button
              size="xs"
              variant="ghost"
              color="slate"
              :label="t('INVITA.PROPOSAL.REPLY_COPY')"
              @click="copyReply"
            />
          </div>
        </section>
      </template>

      <p v-if="errorMessage" class="text-sm break-words text-n-ruby-11">
        {{ errorMessage }}
      </p>

      <section
        v-if="!isReading"
        class="flex flex-col gap-2 pt-3 border-t border-n-weak"
      >
        <label class="text-sm font-medium text-n-slate-12" for="invita-note">
          {{ t('INVITA.PROPOSAL.NOTE_LABEL') }}
        </label>
        <textarea
          id="invita-note"
          v-model="note"
          rows="2"
          :placeholder="t('INVITA.PROPOSAL.NOTE_PLACEHOLDER')"
          class="w-full px-2 py-1 text-sm border rounded-md resize-y border-n-weak bg-n-alpha-black2 text-n-slate-12"
        />
        <div class="flex items-center justify-between gap-3">
          <label class="flex items-center gap-2 text-sm text-n-slate-11">
            <input v-model="readAll" type="checkbox" />
            {{ t('INVITA.PROPOSAL.READ_ALL') }}
          </label>
          <Button
            size="sm"
            variant="outline"
            color="slate"
            :label="t('INVITA.PROPOSAL.READ_AGAIN')"
            @click="read"
          />
        </div>
      </section>
    </div>
  </Dialog>
</template>
