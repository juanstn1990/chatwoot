<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ContactAPI from 'dashboard/api/contacts';

const props = defineProps({
  funnel: { type: Object, required: true },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const opportunityId = ref(null);
const name = ref('');
const description = ref('');
const value = ref('0');
const stageId = ref(null);
const status = ref('open');
const expectedCloseOn = ref('');
const contactId = ref('');
const contactLabel = ref('');
const contactOptions = ref([]);
const conversationDisplayId = ref(null);

const isEditing = computed(() => Boolean(opportunityId.value));

const contactDisplayName = contact =>
  contact.name || contact.email || contact.phone_number || `#${contact.id}`;

const searchContacts = async query => {
  const response = query
    ? await ContactAPI.search(query)
    : await ContactAPI.get(1);
  contactOptions.value = response.data.payload.map(contact => ({
    value: contact.id,
    label: contactDisplayName(contact),
  }));
};

const stageOptions = computed(() =>
  props.funnel.stages.map(stage => ({ value: stage.id, label: stage.name }))
);

const statusOptions = computed(() => [
  { value: 'open', label: t('KANBAN.OPPORTUNITY_FORM.STATUS_OPEN') },
  { value: 'won', label: t('KANBAN.OPPORTUNITY_FORM.STATUS_WON') },
  { value: 'lost', label: t('KANBAN.OPPORTUNITY_FORM.STATUS_LOST') },
]);

const open = (opportunity = null, presetContactId = null, presetConversationId = null) => {
  opportunityId.value = opportunity?.id ?? null;
  name.value = opportunity?.name ?? '';
  description.value = opportunity?.description ?? '';
  value.value = String(opportunity?.value ?? '0');
  stageId.value = opportunity?.funnel_stage_id ?? props.funnel.stages[0]?.id;
  status.value = opportunity?.status ?? 'open';
  expectedCloseOn.value = opportunity?.expected_close_on ?? '';
  contactId.value = opportunity?.contact?.id ?? presetContactId ?? '';
  contactLabel.value = opportunity?.contact
    ? contactDisplayName(opportunity.contact)
    : '';
  contactOptions.value = [];
  conversationDisplayId.value = presetConversationId;
  dialogRef.value.open();
};

const onConfirm = async () => {
  const payload = {
    name: name.value,
    description: description.value,
    value: value.value,
    status: status.value,
    funnel_stage_id: stageId.value,
    contact_id: contactId.value || null,
    conversation_display_id: conversationDisplayId.value || null,
    expected_close_on: expectedCloseOn.value || null,
  };

  try {
    if (isEditing.value) {
      await store.dispatch('opportunities/update', {
        id: opportunityId.value,
        ...payload,
      });
    } else {
      await store.dispatch('opportunities/create', payload);
    }
    useAlert(t('KANBAN.OPPORTUNITY_FORM.SUCCESS_MESSAGE'));
    emit('saved');
    dialogRef.value.close();
  } catch (error) {
    useAlert(error.message || t('KANBAN.OPPORTUNITY_FORM.ERROR_MESSAGE'));
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      isEditing
        ? t('KANBAN.OPPORTUNITY_FORM.EDIT_TITLE')
        : t('KANBAN.OPPORTUNITY_FORM.CREATE_TITLE')
    "
    :confirm-button-label="t('KANBAN.OPPORTUNITY_FORM.SUBMIT')"
    :cancel-button-label="t('KANBAN.OPPORTUNITY_FORM.CANCEL')"
    :disable-confirm-button="!name"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('KANBAN.OPPORTUNITY_FORM.NAME_LABEL')"
        :placeholder="t('KANBAN.OPPORTUNITY_FORM.NAME_PLACEHOLDER')"
      />
      <Input
        v-model="value"
        type="number"
        :label="t('KANBAN.OPPORTUNITY_FORM.VALUE_LABEL')"
        :placeholder="t('KANBAN.OPPORTUNITY_FORM.VALUE_PLACEHOLDER')"
      />
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.OPPORTUNITY_FORM.STAGE_LABEL') }}
        </label>
        <Select v-model="stageId" :options="stageOptions" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.OPPORTUNITY_FORM.CONTACT_LABEL') }}
        </label>
        <ComboBox
          v-model="contactId"
          :options="contactOptions"
          :display-label="contactLabel"
          use-api-results
          :placeholder="t('KANBAN.OPPORTUNITY_FORM.CONTACT_PLACEHOLDER')"
          :search-placeholder="t('KANBAN.OPPORTUNITY_FORM.CONTACT_SEARCH')"
          :empty-state="t('KANBAN.OPPORTUNITY_FORM.CONTACT_EMPTY')"
          @open="searchContacts('')"
          @search="searchContacts"
        />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('KANBAN.OPPORTUNITY_FORM.STATUS_LABEL') }}
        </label>
        <Select v-model="status" :options="statusOptions" />
      </div>
      <Input
        v-model="expectedCloseOn"
        type="date"
        :label="t('KANBAN.OPPORTUNITY_FORM.EXPECTED_CLOSE_LABEL')"
      />
      <Input
        v-model="description"
        :label="t('KANBAN.OPPORTUNITY_FORM.DESCRIPTION_LABEL')"
        :placeholder="t('KANBAN.OPPORTUNITY_FORM.DESCRIPTION_PLACEHOLDER')"
      />
    </div>
  </Dialog>
</template>
