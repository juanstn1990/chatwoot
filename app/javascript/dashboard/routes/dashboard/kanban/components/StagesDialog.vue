<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import draggable from 'vuedraggable';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  funnel: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const labels = useMapGetter('labels/getLabels');

const dialogRef = ref(null);
const stages = ref([]);
const newStageName = ref('');

const labelOptions = computed(() => [
  { value: '', label: t('KANBAN.STAGES.NO_LABEL') },
  ...labels.value.map(label => ({ value: label.id, label: label.title })),
]);

const syncFromFunnel = () => {
  stages.value = props.funnel.stages.map(stage => ({ ...stage }));
};

const open = () => {
  syncFromFunnel();
  newStageName.value = '';
  dialogRef.value.open();
};

const saveStage = async stage => {
  await store.dispatch('funnels/updateStage', {
    funnelId: props.funnel.id,
    id: stage.id,
    name: stage.name,
    color: stage.color,
    label_id: stage.label_id || null,
  });
};

const addStage = async () => {
  if (!newStageName.value) return;

  await store.dispatch('funnels/createStage', {
    funnelId: props.funnel.id,
    name: newStageName.value,
    color: '#64748b',
    position: stages.value.length,
  });
  newStageName.value = '';
};

const removeStage = async stage => {
  try {
    await store.dispatch('funnels/deleteStage', {
      funnelId: props.funnel.id,
      id: stage.id,
    });
  } catch (error) {
    useAlert(error.message || t('KANBAN.STAGES.DELETE_ERROR'));
  }
};

const onReorder = () =>
  store.dispatch('funnels/reorderStages', {
    funnelId: props.funnel.id,
    stages: stages.value,
  });

watch(() => props.funnel, syncFromFunnel, { deep: true });

onMounted(() => store.dispatch('labels/get'));

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('KANBAN.STAGES.TITLE')"
    :description="t('KANBAN.STAGES.DESCRIPTION')"
    :show-confirm-button="false"
    :cancel-button-label="t('KANBAN.STAGES.CLOSE')"
    width="2xl"
    overflow-y-auto
  >
    <div class="flex flex-col gap-3">
      <draggable
        :list="stages"
        item-key="id"
        handle=".stage-handle"
        class="flex flex-col gap-2"
        @end="onReorder"
      >
        <template #item="{ element }">
          <div class="flex items-center gap-2">
            <span class="cursor-grab stage-handle text-n-slate-10">
              <span class="i-lucide-grip-vertical size-4" />
            </span>
            <input
              v-model="element.color"
              type="color"
              class="w-8 h-8 border rounded cursor-pointer border-n-weak bg-n-solid-1"
              @change="saveStage(element)"
            />
            <Input
              v-model="element.name"
              class="flex-1"
              @blur="saveStage(element)"
            />
            <Select
              v-model="element.label_id"
              class="w-48"
              :options="labelOptions"
              :aria-label="t('KANBAN.STAGES.LABEL')"
              @update:model-value="saveStage(element)"
            />
            <Button
              variant="ghost"
              color="ruby"
              size="xs"
              icon="i-lucide-trash-2"
              @click="removeStage(element)"
            />
          </div>
        </template>
      </draggable>

      <div class="flex items-center gap-2 pt-3 border-t border-n-weak">
        <Input
          v-model="newStageName"
          class="flex-1"
          :placeholder="t('KANBAN.STAGES.NEW_PLACEHOLDER')"
          @enter="addStage"
        />
        <Button
          variant="outline"
          color="slate"
          size="sm"
          :label="t('KANBAN.STAGES.ADD')"
          :disabled="!newStageName"
          @click="addStage"
        />
      </div>
    </div>
  </Dialog>
</template>
