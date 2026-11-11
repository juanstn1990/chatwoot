<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InvitationsAPI from 'dashboard/api/invitations';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

// Un solo dialogo para las dos formas de traer una invitacion a la
// conversacion: crear una nueva eligiendo en cual se basa, o enlazar una que
// ya existe.
const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});

const emit = defineEmits(['created', 'linked']);

const { t } = useI18n();

const dialogRef = ref(null);
const mode = ref('create');
const query = ref('');
const groups = ref([]);
const selected = ref(null);
const title = ref('');
const fill = ref(false);
const isSearching = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');

let searchTimer = null;
let searchRun = 0;

const isCreate = computed(() => mode.value === 'create');

const errorOf = error =>
  error?.response?.data?.error || error?.message || t('INVITA.ERROR');

const search = async () => {
  searchRun += 1;
  const run = searchRun;
  isSearching.value = true;
  errorMessage.value = '';
  try {
    if (isCreate.value) {
      const { data } = await InvitationsAPI.sources(
        props.conversationId,
        query.value
      );
      if (run !== searchRun) return;
      groups.value = [
        { label: t('INVITA.SOURCE.SAMPLES'), items: data.muestras ?? [] },
        { label: t('INVITA.SOURCE.TEMPLATES'), items: data.plantillas ?? [] },
        { label: t('INVITA.SOURCE.DESIGNS'), items: data.disenos ?? [] },
      ].filter(group => group.items.length);
    } else {
      const { data } = await InvitationsAPI.search(
        props.conversationId,
        query.value
      );
      if (run !== searchRun) return;
      const items = (data.invitaciones ?? []).map(invitation => ({
        tipo: 'invitacion',
        id: invitation.id,
        titulo: invitation.titulo,
        detalle: `${invitation.diseno} · ${invitation.estadoEtiqueta}`,
        descripcion: invitation.vinculada ? t('INVITA.LINK.ALREADY') : null,
        enlace: invitation.enlace,
      }));
      groups.value = items.length ? [{ label: '', items }] : [];
    }
  } catch (error) {
    if (run === searchRun) errorMessage.value = errorOf(error);
  } finally {
    if (run === searchRun) isSearching.value = false;
  }
};

const onQuery = value => {
  query.value = value;
  clearTimeout(searchTimer);
  searchTimer = setTimeout(search, 300);
};

const isSelected = item =>
  selected.value?.id === item.id && selected.value?.tipo === item.tipo;

const open = nextMode => {
  mode.value = nextMode;
  query.value = '';
  groups.value = [];
  selected.value = null;
  title.value = '';
  fill.value = false;
  errorMessage.value = '';
  dialogRef.value.open();
  search();
};

const linkSelected = async (move = false) => {
  try {
    await InvitationsAPI.link(props.conversationId, selected.value.id, move);
  } catch (error) {
    // Ya enlazada a otra conversacion: moverla es una decision, se pregunta.
    const other = error?.response?.data?.otraConversacion;
    if (error?.response?.status !== 409 || !other || move) throw error;
    // eslint-disable-next-line no-alert
    if (!window.confirm(t('INVITA.LINK.MOVE_CONFIRM', { id: other }))) {
      return false;
    }
    return linkSelected(true);
  }
  return true;
};

const onConfirm = async () => {
  if (!selected.value) return;
  isSaving.value = true;
  errorMessage.value = '';
  try {
    if (isCreate.value) {
      const { data } = await InvitationsAPI.create(props.conversationId, {
        origin: { type: selected.value.tipo, id: selected.value.id },
        title: title.value,
      });
      useAlert(t('INVITA.CREATED'));
      emit('created', { invitation: data.invitacion, fill: fill.value });
      dialogRef.value.close();
    } else if (await linkSelected()) {
      useAlert(t('INVITA.LINKED'));
      emit('linked');
      dialogRef.value.close();
    }
  } catch (error) {
    errorMessage.value = errorOf(error);
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    :title="isCreate ? t('INVITA.SOURCE.TITLE') : t('INVITA.LINK.TITLE')"
    :description="
      isCreate ? t('INVITA.SOURCE.DESCRIPTION') : t('INVITA.LINK.DESCRIPTION')
    "
    :confirm-button-label="
      isCreate ? t('INVITA.SOURCE.SUBMIT') : t('INVITA.LINK.SUBMIT')
    "
    :cancel-button-label="t('INVITA.CANCEL')"
    :disable-confirm-button="!selected"
    :is-loading="isSaving"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        :model-value="query"
        :placeholder="
          isCreate
            ? t('INVITA.SOURCE.SEARCH_PLACEHOLDER')
            : t('INVITA.LINK.SEARCH_PLACEHOLDER')
        "
        @update:model-value="onQuery"
      />

      <div
        class="flex flex-col gap-3 overflow-y-auto border rounded-lg max-h-72 border-n-weak p-2"
      >
        <div v-if="isSearching" class="flex justify-center py-4">
          <Spinner :size="20" />
        </div>
        <p
          v-else-if="!groups.length"
          class="py-4 text-sm text-center text-n-slate-11"
        >
          {{ t('INVITA.SOURCE.NO_RESULTS') }}
        </p>
        <template v-else>
          <div v-for="group in groups" :key="group.label">
            <p
              v-if="group.label"
              class="px-2 pb-1 text-xs font-medium uppercase text-n-slate-10"
            >
              {{ group.label }}
            </p>
            <button
              v-for="item in group.items"
              :key="`${item.tipo}-${item.id}`"
              type="button"
              class="flex flex-col w-full gap-0.5 px-2 py-1.5 text-left rounded-md"
              :class="
                isSelected(item)
                  ? 'bg-n-brand/10 outline outline-1 outline-n-brand'
                  : 'hover:bg-n-alpha-2'
              "
              @click="selected = item"
            >
              <span class="flex items-center justify-between gap-2">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ item.titulo }}
                </span>
                <a
                  v-if="item.enlace"
                  :href="item.enlace"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-xs shrink-0 text-n-blue-11 hover:underline"
                  @click.stop
                >
                  {{ t('INVITA.VIEW') }}
                </a>
              </span>
              <span class="text-xs text-n-slate-11">{{ item.detalle }}</span>
              <span v-if="item.descripcion" class="text-xs text-n-slate-10">
                {{ item.descripcion }}
              </span>
            </button>
          </div>
        </template>
      </div>

      <template v-if="isCreate">
        <Input
          v-model="title"
          :label="t('INVITA.SOURCE.TITLE_LABEL')"
          :placeholder="t('INVITA.SOURCE.TITLE_PLACEHOLDER')"
        />
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input v-model="fill" type="checkbox" />
          {{ t('INVITA.SOURCE.FILL') }}
        </label>
      </template>

      <p v-if="errorMessage" class="text-sm break-words text-n-ruby-11">
        {{ errorMessage }}
      </p>
    </div>
  </Dialog>
</template>
