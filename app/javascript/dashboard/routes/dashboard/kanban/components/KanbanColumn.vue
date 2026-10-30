<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';

import OpportunityCard from './OpportunityCard.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  opportunities: { type: Array, default: () => [] },
  currency: { type: String, default: 'USD' },
});

const emit = defineEmits(['move', 'edit', 'openConversation']);

const { t } = useI18n();

const stageTotal = computed(() =>
  new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: props.currency,
    maximumFractionDigits: 0,
  }).format(
    props.opportunities.reduce(
      (total, opportunity) => total + Number(opportunity.value || 0),
      0
    )
  )
);

const onChange = event => {
  const change = event.added || event.moved;
  if (!change) return;

  emit('move', {
    id: change.element.id,
    funnelStageId: props.stage.id,
    position: change.newIndex,
  });
};
</script>

<template>
  <section class="flex flex-col w-72 shrink-0 gap-3 p-3 rounded-xl bg-n-alpha-1">
    <header class="flex flex-col gap-1">
      <div class="flex items-center gap-2">
        <span
          class="size-2 rounded-full shrink-0"
          :style="{ backgroundColor: stage.color }"
        />
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ stage.name }}
        </span>
        <span class="text-xs text-n-slate-10">
          {{ opportunities.length }}
        </span>
      </div>
      <span class="text-xs text-n-slate-11">{{ stageTotal }}</span>
    </header>

    <draggable
      :list="opportunities"
      item-key="id"
      group="opportunities"
      class="flex flex-col gap-2 min-h-12"
      @change="onChange"
    >
      <template #item="{ element }">
        <OpportunityCard
          :opportunity="element"
          :currency="currency"
          @edit="emit('edit', $event)"
          @open-conversation="emit('openConversation', $event)"
        />
      </template>
    </draggable>

    <p
      v-if="!opportunities.length"
      class="text-xs text-center text-n-slate-10"
    >
      {{ t('KANBAN.COLUMN.EMPTY') }}
    </p>
  </section>
</template>
