<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  opportunity: { type: Object, required: true },
  currency: { type: String, default: 'USD' },
});

defineEmits(['edit', 'openConversation']);

const { t } = useI18n();

const formattedValue = computed(() =>
  new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: props.currency,
    maximumFractionDigits: 2,
  }).format(Number(props.opportunity.value || 0))
);

const contactName = computed(() => props.opportunity.contact?.name);
const assigneeName = computed(() => props.opportunity.assignee?.name);
const conversationId = computed(
  () => props.opportunity.conversation_display_id
);
</script>

<template>
  <div
    class="relative border rounded-lg cursor-grab bg-n-solid-1 border-n-weak hover:border-n-strong"
  >
    <button
      class="flex flex-col w-full gap-1 p-3 text-start"
      @click="$emit('edit', opportunity)"
    >
      <span
        class="text-sm font-medium truncate pe-7"
        :class="contactName ? 'text-n-slate-12' : 'text-n-slate-10 italic'"
      >
        {{ contactName || t('KANBAN.CARD.NO_CONTACT') }}
      </span>
      <span class="text-sm text-n-slate-11 line-clamp-2">
        {{ opportunity.name }}
      </span>
      <span class="mt-1 text-sm font-semibold text-n-slate-12">
        {{ formattedValue }}
      </span>
      <span v-if="assigneeName" class="text-xs truncate text-n-slate-10">
        {{ assigneeName }}
      </span>
    </button>

    <Button
      v-if="conversationId"
      variant="ghost"
      color="slate"
      size="xs"
      icon="i-lucide-messages-square"
      class="absolute top-2 end-2"
      :title="t('KANBAN.CARD.OPEN_CONVERSATION')"
      @click.stop="$emit('openConversation', conversationId)"
    />
  </div>
</template>
