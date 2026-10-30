<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import OpportunityDialog from 'dashboard/routes/dashboard/kanban/components/OpportunityDialog.vue';

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  conversationId: { type: [Number, String], default: null },
});

const { t } = useI18n();
const store = useStore();

const funnels = useMapGetter('funnels/getFunnels');
const opportunityDialogRef = ref(null);
const contactOpportunities = ref([]);

const defaultFunnel = computed(() => funnels.value[0]);

const funnelFor = opportunity =>
  funnels.value.find(funnel => funnel.id === opportunity.funnel_id);

const stageOptionsFor = opportunity =>
  (funnelFor(opportunity)?.stages ?? []).map(stage => ({
    value: stage.id,
    label: stage.name,
  }));

const formatValue = opportunity =>
  new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: opportunity.currency || 'USD',
    maximumFractionDigits: 0,
  }).format(Number(opportunity.value || 0));

const fetchOpportunities = async () => {
  const records = await store.dispatch(
    'opportunities/getByContact',
    props.contactId
  );
  contactOpportunities.value = records ?? [];
};

const onStageChange = async (opportunity, funnelStageId) => {
  if (!funnelStageId || funnelStageId === opportunity.funnel_stage_id) return;

  await store.dispatch('opportunities/move', {
    id: opportunity.id,
    funnelStageId,
    position: 0,
  });
  await fetchOpportunities();
};

watch(() => props.contactId, fetchOpportunities);

onMounted(async () => {
  await store.dispatch('funnels/get');
  await fetchOpportunities();
});
</script>

<template>
  <div class="flex flex-col gap-3">
    <div
      v-for="opportunity in contactOpportunities"
      :key="opportunity.id"
      class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak"
    >
      <div class="flex items-start justify-between gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ opportunity.name }}
        </span>
        <span class="text-sm font-semibold shrink-0 text-n-slate-11">
          {{ formatValue(opportunity) }}
        </span>
      </div>
      <Select
        :model-value="opportunity.funnel_stage_id"
        :options="stageOptionsFor(opportunity)"
        :aria-label="t('KANBAN.OPPORTUNITY_FORM.STAGE_LABEL')"
        @update:model-value="onStageChange(opportunity, $event)"
      />
    </div>

    <p
      v-if="!contactOpportunities.length"
      class="text-sm text-n-slate-11"
    >
      {{ t('KANBAN.SIDEBAR.EMPTY') }}
    </p>

    <Button
      v-if="defaultFunnel"
      variant="outline"
      color="slate"
      size="sm"
      :label="t('KANBAN.SIDEBAR.ADD')"
      @click="opportunityDialogRef.open(null, contactId, conversationId)"
    />

    <OpportunityDialog
      v-if="defaultFunnel"
      ref="opportunityDialogRef"
      :funnel="defaultFunnel"
      @saved="fetchOpportunities"
    />
  </div>
</template>
