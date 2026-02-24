<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useI18n } from './i18n'
import type { FileAssocItem, AppInfo } from './types'

const { t, currentLocale, toggleLocale } = useI18n()

// ==================== 状态 ====================
const allItems = ref<FileAssocItem[]>([])
const searchQuery = ref('')
const loading = ref(true)
const refreshing = ref(false)
const toast = ref<{ message: string; type: 'success' | 'error' } | null>(null)
const showModal = ref(false)
const selectedItem = ref<FileAssocItem | null>(null)

// 批量替换相关状态
const showBatchModal = ref(false)
const batchSourceBundle = ref<string | null>(null)
const batchTargetBundle = ref<string | null>(null)
const batchProcessing = ref(false)

// ==================== 计算属性 ====================
/** 根据搜索关键词过滤的列表 */
const filteredItems = computed(() => {
  const q = searchQuery.value.toLowerCase().trim()
  if (!q) return allItems.value
  return allItems.value.filter(
    (item) =>
      item.ext.toLowerCase().includes(q) ||
      item.uti.toLowerCase().includes(q) ||
      (item.defaultApp?.name?.toLowerCase().includes(q) ?? false)
  )
})

// ==================== 后缀颜色映射 ====================
const categoryColors: Record<string, string> = {
  // 文本/代码
  txt: '#a5b4fc', html: '#a5b4fc', css: '#a5b4fc',
  js: '#facc15', ts: '#3b82f6', json: '#facc15',
  xml: '#f97316', yaml: '#ef4444', yml: '#ef4444',
  toml: '#f97316', ini: '#9ca3af', cfg: '#9ca3af',
  conf: '#9ca3af', log: '#9ca3af', md: '#60a5fa', csv: '#34d399',
  // 编程语言
  py: '#fbbf24', rb: '#ef4444', java: '#f97316',
  c: '#60a5fa', cpp: '#60a5fa', h: '#60a5fa',
  swift: '#f97316', go: '#22d3ee', rs: '#f97316',
  sh: '#4ade80', bat: '#9ca3af', ps1: '#60a5fa',
  // 数据库
  sql: '#f472b6', db: '#f472b6', sqlite: '#f472b6',
  // 文档
  pdf: '#ef4444', doc: '#3b82f6', docx: '#3b82f6',
  xls: '#22c55e', xlsx: '#22c55e', ppt: '#f97316', pptx: '#f97316', rtf: '#818cf8',
  // 图片
  jpg: '#ec4899', jpeg: '#ec4899', png: '#8b5cf6', gif: '#f472b6',
  bmp: '#a78bfa', tiff: '#a78bfa', svg: '#facc15', webp: '#34d399',
  ico: '#9ca3af', heic: '#ec4899',
  // 音频
  mp3: '#22d3ee', wav: '#22d3ee', flac: '#14b8a6',
  aac: '#06b6d4', ogg: '#06b6d4', wma: '#06b6d4', m4a: '#22d3ee', aiff: '#14b8a6',
  // 视频
  mp4: '#a855f7', mkv: '#a855f7', avi: '#9333ea', mov: '#a855f7',
  wmv: '#9333ea', flv: '#7c3aed', webm: '#8b5cf6', m4v: '#a855f7',
  // 压缩包
  zip: '#f59e0b', rar: '#f59e0b', '7z': '#f59e0b', tar: '#f59e0b',
  gz: '#f59e0b', bz2: '#f59e0b', xz: '#f59e0b', dmg: '#9ca3af', iso: '#9ca3af',
  // 设计
  ai: '#f97316', psd: '#3b82f6', sketch: '#facc15', fig: '#a855f7',
  // 字体
  ttf: '#6b7280', otf: '#6b7280', woff: '#6b7280', woff2: '#6b7280',
  // 可执行
  ipa: '#60a5fa', apk: '#4ade80', exe: '#60a5fa',
  app: '#9ca3af', pkg: '#9ca3af', deb: '#ef4444'
}

function getColor(ext: string): string {
  return categoryColors[ext] || '#6b7280'
}

// ==================== 数据操作 ====================
/** 加载文件关联数据 */
async function loadData() {
  try {
    const data = await window.fileAssocAPI.list()
    allItems.value = data || []
  } catch (e) {
    console.error('Load failed:', e)
    showToast(t.value('toast.loadFailed'), 'error')
  }
}

/** 刷新数据 */
async function refresh() {
  refreshing.value = true
  await loadData()
  refreshing.value = false
  showToast(t.value('toast.refreshed'), 'success')
}

/** 打开修改弹窗 */
function openChangeModal(item: FileAssocItem) {
  selectedItem.value = item
  showModal.value = true
}

/** 关闭弹窗 */
function closeModal() {
  showModal.value = false
  selectedItem.value = null
}

/** 设置默认应用 */
async function setDefaultApp(app: AppInfo) {
  if (!selectedItem.value) return
  const ext = selectedItem.value.ext
  try {
    const result = await window.fileAssocAPI.set(ext, app.bundleId)
    if (result.success) {
      showToast(t.value('toast.setSuccess', { ext, app: app.name }), 'success')
      const idx = allItems.value.findIndex((i) => i.ext === ext)
      if (idx >= 0) {
        allItems.value[idx].defaultApp = app
      }
      closeModal()
    } else {
      showToast(t.value('toast.setFailed', { error: result.error || '' }), 'error')
    }
  } catch (e) {
    showToast(t.value('toast.setError'), 'error')
  }
}

// ==================== 批量替换 ====================
/** 所有作为默认应用的唯一应用列表（用于来源选择） */
const uniqueDefaultApps = computed(() => {
  const map = new Map<string, { app: AppInfo; count: number }>()
  for (const item of allItems.value) {
    if (item.defaultApp) {
      const key = item.defaultApp.bundleId
      if (map.has(key)) {
        map.get(key)!.count++
      } else {
        map.set(key, { app: item.defaultApp, count: 1 })
      }
    }
  }
  return Array.from(map.values()).sort((a, b) => b.count - a.count)
})

/** 选中来源应用后，受影响的后缀列表 */
const batchAffectedItems = computed(() => {
  if (!batchSourceBundle.value) return []
  return allItems.value.filter(
    (item) => item.defaultApp?.bundleId === batchSourceBundle.value
  )
})

/** 来源应用名称 */
const batchSourceAppName = computed(() => {
  const found = uniqueDefaultApps.value.find(
    (item) => item.app.bundleId === batchSourceBundle.value
  )
  return found?.app.name ?? ''
})

/** 目标应用名称 */
const batchTargetAppName = computed(() => {
  const found = batchTargetApps.value.find(
    (app) => app.bundleId === batchTargetBundle.value
  )
  return found?.name ?? ''
})

/** 可用的目标应用列表（所有受影响后缀的可用应用的并集，排除来源应用） */
const batchTargetApps = computed(() => {
  const map = new Map<string, AppInfo>()
  for (const item of batchAffectedItems.value) {
    for (const app of item.availableApps) {
      if (app.bundleId !== batchSourceBundle.value && !map.has(app.bundleId)) {
        map.set(app.bundleId, app)
      }
    }
  }
  return Array.from(map.values()).sort((a, b) => a.name.localeCompare(b.name))
})

function openBatchModal() {
  batchSourceBundle.value = null
  batchTargetBundle.value = null
  showBatchModal.value = true
}

function closeBatchModal() {
  showBatchModal.value = false
  batchSourceBundle.value = null
  batchTargetBundle.value = null
}

function selectBatchSource(bundleId: string) {
  batchSourceBundle.value = bundleId
  batchTargetBundle.value = null
}

function selectBatchTarget(bundleId: string) {
  batchTargetBundle.value = bundleId
}

async function executeBatchReplace() {
  if (!batchSourceBundle.value || !batchTargetBundle.value) return
  const extensions = batchAffectedItems.value.map((item) => item.ext)
  if (extensions.length === 0) return

  batchProcessing.value = true
  try {
    const results = await window.fileAssocAPI.batchSet(extensions, batchTargetBundle.value)
    const successCount = results.filter((r) => r.success).length
    const failCount = results.length - successCount

    // 更新本地数据
    const targetApp = batchTargetApps.value.find(
      (a) => a.bundleId === batchTargetBundle.value
    )
    if (targetApp) {
      for (const r of results) {
        if (r.success) {
          const idx = allItems.value.findIndex((i) => i.ext === r.ext)
          if (idx >= 0) {
            allItems.value[idx].defaultApp = targetApp
          }
        }
      }
    }

    showToast(
      t.value('toast.batchSuccess', {
        success: String(successCount),
        fail: String(failCount)
      }),
      failCount === 0 ? 'success' : 'error'
    )
    closeBatchModal()
  } catch (e) {
    showToast(t.value('toast.batchError'), 'error')
  } finally {
    batchProcessing.value = false
  }
}

// ==================== Toast 通知 ====================
let toastTimer: ReturnType<typeof setTimeout> | null = null

function showToast(message: string, type: 'success' | 'error') {
  if (toastTimer) clearTimeout(toastTimer)
  toast.value = { message, type }
  toastTimer = setTimeout(() => {
    toast.value = null
  }, 3000)
}

// ==================== 生命周期 ====================
/** ESC 键关闭弹窗 */
function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    if (showBatchModal.value) {
      closeBatchModal()
    } else if (showModal.value) {
      closeModal()
    }
  }
}

onMounted(async () => {
  document.addEventListener('keydown', handleKeydown)
  await loadData()
  loading.value = false
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <!-- 标题栏 -->
  <div class="titlebar">
    <h1>{{ t('app.title') }}</h1>
    <span class="subtitle">{{ t('app.subtitle') }}</span>
  </div>

  <!-- 工具栏 -->
  <div class="toolbar">
    <div class="search-container">
      <span class="search-icon">🔍</span>
      <input
        v-model="searchQuery"
        class="search-input"
        :placeholder="t('search.placeholder')"
        type="text"
      />
    </div>

    <div class="stat-badge">
      <span>{{ filteredItems.length }}</span>
      <span>/ {{ allItems.length }} {{ t('stat.suffix') }}</span>
    </div>

    <button
      class="lang-btn"
      @click="toggleLocale"
      :title="currentLocale === 'zh-CN' ? 'Switch to English' : '切换为中文'"
    >
      {{ t('lang.switch') }}
    </button>

    <button class="batch-btn" @click="openBatchModal">
      🔄 {{ t('btn.batchReplace') }}
    </button>

    <button
      class="refresh-btn"
      :class="{ spinning: refreshing }"
      @click="refresh"
      :disabled="refreshing"
    >
      <span class="refresh-icon">↻</span>
      {{ t('btn.refresh') }}
    </button>
  </div>

  <!-- 加载状态 -->
  <div v-if="loading" class="loading-container">
    <div class="loading-spinner"></div>
    <span class="loading-text">{{ t('loading.text') }}</span>
  </div>

  <!-- 数据表格 -->
  <div v-else-if="filteredItems.length > 0" class="table-wrapper">
    <table>
      <thead>
        <tr>
          <th style="width: 100px">{{ t('table.ext') }}</th>
          <th style="width: 260px" :title="t('table.uti.tooltip')">{{ t('table.uti') }}</th>
          <th>{{ t('table.defaultApp') }}</th>
          <th style="width: 90px">{{ t('table.availableCount') }}</th>
          <th style="width: 80px">{{ t('table.action') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in filteredItems" :key="item.ext">
          <td>
            <div class="ext-cell">
              <span class="ext-dot" :style="{ background: getColor(item.ext) }"></span>
              <span class="ext-name">.{{ item.ext }}</span>
            </div>
          </td>
          <td>
            <span class="uti-text" :title="item.uti">{{ item.uti }}</span>
          </td>
          <td>
            <span v-if="item.defaultApp" class="app-badge">
              <span class="app-name">{{ item.defaultApp.name }}</span>
            </span>
            <span v-else class="no-app">{{ t('table.notSet') }}</span>
          </td>
          <td>
            <span style="color: var(--text-secondary); font-size: 12px">
              {{ item.availableApps.length }} {{ t('table.unit') }}
            </span>
          </td>
          <td>
            <button
              class="change-btn"
              @click="openChangeModal(item)"
              :disabled="item.availableApps.length === 0"
            >
              {{ t('btn.change') }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <!-- 空状态 -->
  <div v-else class="empty-state">
    <span class="empty-icon">🔍</span>
    <p>{{ t('empty.text') }}</p>
  </div>

  <!-- 修改默认应用弹窗 -->
  <div
    v-if="showModal && selectedItem"
    class="modal-overlay"
    @click.self="closeModal"
  >
    <div class="modal">
      <div class="modal-header">
        <h2>
          {{ t('modal.title') }}
          <span class="modal-ext">.{{ selectedItem.ext }}</span>
          {{ t('modal.titleSuffix') }}
        </h2>
        <p>{{ t('modal.utiLabel') }}: {{ selectedItem.uti }}</p>
      </div>
      <div class="modal-body">
        <div
          v-for="app in selectedItem.availableApps"
          :key="app.bundleId"
          class="app-option"
          :class="{ current: selectedItem.defaultApp?.bundleId === app.bundleId }"
          @click="setDefaultApp(app)"
        >
          <div class="app-icon">📦</div>
          <div class="app-option-info">
            <div class="app-option-name">{{ app.name }}</div>
            <div class="app-option-id">{{ app.bundleId }}</div>
          </div>
          <span
            v-if="selectedItem.defaultApp?.bundleId === app.bundleId"
            class="current-tag"
          >
            {{ t('modal.currentTag') }}
          </span>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-cancel" @click="closeModal">
          {{ t('btn.close') }}
        </button>
      </div>
    </div>
  </div>

  <!-- 批量替换弹窗 -->
  <div
    v-if="showBatchModal"
    class="modal-overlay"
    @click.self="closeBatchModal"
  >
    <div class="modal batch-modal">
      <!-- 第一步：选择来源应用 -->
      <template v-if="!batchSourceBundle">
        <div class="modal-header">
          <h2>🔄 {{ t('batch.title') }}</h2>
          <p>{{ t('batch.desc') }}</p>
        </div>
        <div class="modal-body">
          <div class="batch-label">{{ t('batch.sourceLabel') }}</div>
          <div
            v-for="item in uniqueDefaultApps"
            :key="item.app.bundleId"
            class="app-option"
            @click="selectBatchSource(item.app.bundleId)"
          >
            <div class="app-icon">📦</div>
            <div class="app-option-info">
              <div class="app-option-name">{{ item.app.name }}</div>
              <div class="app-option-id">{{ item.app.bundleId }}</div>
            </div>
            <span class="batch-count-tag">
              {{ t('batch.extCount', { count: String(item.count) }) }}
            </span>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeBatchModal">
            {{ t('btn.close') }}
          </button>
        </div>
      </template>

      <!-- 第二步：展示受影响后缀 + 选择目标应用 -->
      <template v-else>
        <div class="modal-header">
          <div class="batch-step-header">
            <button class="btn-back" @click="batchSourceBundle = null">← {{ t('batch.back') }}</button>
            <h2>{{ t('batch.targetLabel') }}</h2>
          </div>
          <!-- 来源应用信息 -->
          <div class="batch-source-info">
            <span>📦 {{ batchSourceAppName }}</span>
            <span class="batch-arrow">→</span>
            <span class="batch-target-hint" v-if="!batchTargetBundle">?</span>
            <span class="batch-target-selected" v-else>📦 {{ batchTargetAppName }}</span>
          </div>
          <!-- 受影响的后缀标签 -->
          <div class="batch-ext-tags">
            <span
              v-for="item in batchAffectedItems"
              :key="item.ext"
              class="batch-ext-tag"
              :style="{ borderColor: getColor(item.ext) + '80' }"
            >
              .{{ item.ext }}
            </span>
          </div>
        </div>
        <div class="modal-body">
          <div v-if="batchTargetApps.length > 0">
            <div
              v-for="app in batchTargetApps"
              :key="app.bundleId"
              class="app-option"
              :class="{ current: batchTargetBundle === app.bundleId }"
              @click="selectBatchTarget(app.bundleId)"
            >
              <div class="app-icon">📦</div>
              <div class="app-option-info">
                <div class="app-option-name">{{ app.name }}</div>
                <div class="app-option-id">{{ app.bundleId }}</div>
              </div>
            </div>
          </div>
          <div v-else class="batch-empty">{{ t('batch.noApps') }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeBatchModal">
            {{ t('btn.close') }}
          </button>
          <button
            v-if="batchTargetBundle"
            class="btn-batch-confirm"
            @click="executeBatchReplace"
            :disabled="batchProcessing"
          >
            <template v-if="batchProcessing">{{ t('batch.processing') }}</template>
            <template v-else>{{ t('btn.batchConfirm') }} ({{ batchAffectedItems.length }})</template>
          </button>
        </div>
      </template>
    </div>
  </div>

  <!-- Toast 通知 -->
  <Transition name="fade">
    <div v-if="toast" class="toast" :class="toast.type">
      {{ toast.message }}
    </div>
  </Transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 200ms, transform 200ms;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(8px);
}
</style>
