<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import KanbanColumn from './components/KanbanColumn.vue';
import FunnelDialog from './components/FunnelDialog.vue';
import OpportunityDialog from './components/OpportunityDialog.vue';
import StagesDialog from './components/StagesDialog.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const funnels = useMapGetter('funnels/getFunnels');
const funnelUiFlags = useMapGetter('funnels/getUIFlags');
const opportunities = useMapGetter('opportunities/getOpportunities');

const selectedFunnelId = ref(null);
const funnelDialogRef = ref(null);
const opportunityDialogRef = ref(null);
const stagesDialogRef = ref(null);

const selectedFunnel = computed(() =>
  funnels.value.find(funnel => funnel.id === selectedFunnelId.value)
);

const funnelOptions = computed(() =>
  funnels.value.map(funnel => ({ value: funnel.id, label: funnel.name }))
);

const currency = computed(() => selectedFunnel.value?.currency ?? 'USD');

const openValue = computed(() =>
  new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: currency.value,
    maximumFractionDigits: 0,
  }).format(
    opportunities.value
      .filter(opportunity => opportunity.status === 'open')
      .reduce((total, opportunity) => total + Number(opportunity.value || 0), 0)
  )
);

const opportunitiesForStage = stageId =>
  opportunities.value
    .filter(opportunity => opportunity.funnel_stage_id === stageId)
    .sort((a, b) => a.position - b.position);

const fetchOpportunities = () => {
  if (selectedFunnelId.value) {
    store.dispatch('opportunities/get', selectedFunnelId.value);
  }
};

const onMove = async ({ id, funnelStageId, position }) => {
  await store.dispatch('opportunities/move', {
    id,
    funnelStageId,
    position,
    funnelId: selectedFunnelId.value,
  });
};

const openConversation = conversationId => {
  router.push(
    accountScopedRoute('inbox_conversation', { conversation_id: conversationId })
  );
};

const onFunnelCreated = funnel => {
  if (funnel) selectedFunnelId.value = funnel.id;
};

watch(selectedFunnelId, fetchOpportunities);

watch(funnels, list => {
  if (!selectedFunnelId.value && list.length) {
    selectedFunnelId.value = list[0].id;
  }
});

onMounted(() => store.dispatch('funnels/get'));
</script>

<template>
  <main class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header
      class="flex items-center justify-between gap-4 px-6 py-4 border-b border-n-weak"
    >
      <div class="flex items-center gap-3">
        <h1 class="text-lg font-medium text-n-slate-12">
          {{ t('KANBAN.HEADER') }}
        </h1>
        <Select
          v-if="funnelOptions.length"
          v-model="selectedFunnelId"
          :options="funnelOptions"
          :aria-label="t('KANBAN.FUNNEL_LABEL')"
        />
      </div>
      <div class="flex items-center gap-3">
        <span v-if="selectedFunnel" class="text-sm text-n-slate-11">
          {{ t('KANBAN.OPEN_VALUE') }}: {{ openValue }}
        </span>
        <Button
          variant="outline"
          color="slate"
          size="sm"
          :label="t('KANBAN.NEW_FUNNEL')"
          @click="funnelDialogRef.open()"
        />
        <Button
          v-if="selectedFunnel"
          variant="outline"
          color="slate"
          size="sm"
          icon="i-lucide-settings-2"
          :label="t('KANBAN.STAGES.BUTTON')"
          @click="stagesDialogRef.open()"
        />
        <Button
          v-if="selectedFunnel"
          variant="solid"
          color="blue"
          size="sm"
          :label="t('KANBAN.NEW_OPPORTUNITY')"
          @click="opportunityDialogRef.open()"
        />
      </div>
    </header>

    <div
      v-if="funnelUiFlags.isFetching"
      class="flex items-center justify-center flex-1"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!funnels.length"
      class="flex flex-col items-center justify-center flex-1 gap-3"
    >
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('KANBAN.EMPTY_STATE.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('KANBAN.EMPTY_STATE.SUBTITLE') }}
      </p>
      <Button
        variant="solid"
        color="blue"
        size="sm"
        :label="t('KANBAN.EMPTY_STATE.ACTION')"
        @click="funnelDialogRef.open()"
      />
    </div>

    <div v-else-if="selectedFunnel" class="flex gap-4 p-6 overflow-x-auto">
      <KanbanColumn
        v-for="stage in selectedFunnel.stages"
        :key="stage.id"
        :stage="stage"
        :opportunities="opportunitiesForStage(stage.id)"
        :currency="currency"
        @move="onMove"
        @edit="opportunityDialogRef.open($event)"
        @open-conversation="openConversation"
      />
    </div>

    <FunnelDialog ref="funnelDialogRef" @created="onFunnelCreated" />
    <StagesDialog
      v-if="selectedFunnel"
      ref="stagesDialogRef"
      :funnel="selectedFunnel"
    />
    <OpportunityDialog
      v-if="selectedFunnel"
      ref="opportunityDialogRef"
      :funnel="selectedFunnel"
      @saved="fetchOpportunities"
    />
  </main>
</template>
