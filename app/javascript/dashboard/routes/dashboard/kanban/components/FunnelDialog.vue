<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['created']);

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const name = ref('');
const description = ref('');
const currency = ref('USD');

const open = () => {
  name.value = '';
  description.value = '';
  currency.value = 'USD';
  dialogRef.value.open();
};

const onConfirm = async () => {
  try {
    const funnel = await store.dispatch('funnels/create', {
      name: name.value,
      description: description.value,
      currency: currency.value,
    });
    useAlert(t('KANBAN.FUNNEL_FORM.SUCCESS_MESSAGE'));
    emit('created', funnel);
    dialogRef.value.close();
  } catch (error) {
    useAlert(error.message || t('KANBAN.FUNNEL_FORM.ERROR_MESSAGE'));
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('KANBAN.FUNNEL_FORM.TITLE')"
    :confirm-button-label="t('KANBAN.FUNNEL_FORM.SUBMIT')"
    :cancel-button-label="t('KANBAN.FUNNEL_FORM.CANCEL')"
    :disable-confirm-button="!name"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('KANBAN.FUNNEL_FORM.NAME_LABEL')"
        :placeholder="t('KANBAN.FUNNEL_FORM.NAME_PLACEHOLDER')"
      />
      <Input
        v-model="description"
        :label="t('KANBAN.FUNNEL_FORM.DESCRIPTION_LABEL')"
        :placeholder="t('KANBAN.FUNNEL_FORM.DESCRIPTION_PLACEHOLDER')"
      />
      <Input
        v-model="currency"
        :label="t('KANBAN.FUNNEL_FORM.CURRENCY_LABEL')"
        :placeholder="t('KANBAN.FUNNEL_FORM.CURRENCY_PLACEHOLDER')"
      />
    </div>
  </Dialog>
</template>
