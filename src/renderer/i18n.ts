import { ref, computed } from 'vue'

export type Locale = 'zh-CN' | 'en'

const STORAGE_KEY = 'file-assoc-manager-locale'

/** 从 localStorage 读取保存的语言设置 */
function getSavedLocale(): Locale {
    try {
        const saved = localStorage.getItem(STORAGE_KEY) as Locale | null
        if (saved === 'zh-CN' || saved === 'en') return saved
    } catch { }

    // 根据系统语言自动选择
    if (typeof navigator !== 'undefined') {
        const lang = navigator.language
        if (lang.startsWith('zh')) return 'zh-CN'
    }
    return 'en'
}

const currentLocale = ref<Locale>(getSavedLocale())

function setLocale(locale: Locale) {
    currentLocale.value = locale
    try {
        localStorage.setItem(STORAGE_KEY, locale)
    } catch { }
}

/** 国际化消息映射 */
const messages: Record<Locale, Record<string, string>> = {
    'zh-CN': {
        'app.title': '📁 文件关联管理器',
        'app.subtitle': '查询与修改 macOS 文件后缀的默认打开方式',
        'search.placeholder': '搜索后缀名、类型标识或应用名...',
        'stat.suffix': '个后缀',
        'btn.refresh': '刷新',
        'table.ext': '后缀',
        'table.uti': '系统类型标识',
        'table.uti.tooltip': 'Uniform Type Identifier — macOS 用来识别文件类型的系统标识',
        'table.defaultApp': '默认应用',
        'table.availableCount': '可选数',
        'table.action': '操作',
        'table.unit': '个',
        'table.notSet': '未设置',
        'btn.change': '修改',
        'modal.title': '修改',
        'modal.titleSuffix': '的默认应用',
        'modal.utiLabel': '系统类型标识',
        'modal.currentTag': '当前',
        'btn.close': '关闭',
        'loading.text': '正在加载文件关联数据...',
        'empty.text': '没有找到匹配的文件后缀',
        'toast.refreshed': '数据已刷新',
        'toast.loadFailed': '加载文件关联数据失败',
        'toast.setSuccess': '已将 .{ext} 的默认应用设置为 {app}',
        'toast.setFailed': '设置失败: {error}',
        'toast.setError': '设置默认应用失败',
        'lang.switch': 'EN',
        'btn.batchReplace': '批量替换',
        'batch.title': '批量替换默认应用',
        'batch.desc': '将某个应用关联的所有文件类型替换为另一个应用',
        'batch.sourceLabel': '替换来源（当前默认应用）',
        'batch.targetLabel': '替换目标（新默认应用）',
        'batch.extCount': '{count} 个后缀',
        'batch.affectedExts': '将影响 {count} 个文件后缀',
        'batch.selectSource': '请先选择来源应用',
        'batch.selectTarget': '请选择目标应用',
        'batch.noApps': '没有可用的替换目标',
        'btn.batchConfirm': '确认替换',
        'batch.processing': '正在批量替换...',
        'toast.batchSuccess': '批量替换完成：{success} 个成功，{fail} 个失败',
        'toast.batchError': '批量替换失败',
        'batch.back': '返回'
    },
    en: {
        'app.title': '📁 File Assoc Manager',
        'app.subtitle': 'Query & modify default apps for file extensions on macOS',
        'search.placeholder': 'Search extensions, type identifiers or app names...',
        'stat.suffix': 'extensions',
        'btn.refresh': 'Refresh',
        'table.ext': 'Ext',
        'table.uti': 'Type Identifier',
        'table.uti.tooltip': 'Uniform Type Identifier — System identifier used by macOS to recognize file types',
        'table.defaultApp': 'Default App',
        'table.availableCount': 'Available',
        'table.action': 'Action',
        'table.unit': '',
        'table.notSet': 'Not set',
        'btn.change': 'Change',
        'modal.title': 'Change default app for',
        'modal.titleSuffix': '',
        'modal.utiLabel': 'Type Identifier',
        'modal.currentTag': 'Current',
        'btn.close': 'Close',
        'loading.text': 'Loading file associations...',
        'empty.text': 'No matching file extensions found',
        'toast.refreshed': 'Data refreshed',
        'toast.loadFailed': 'Failed to load file associations',
        'toast.setSuccess': 'Set default app for .{ext} to {app}',
        'toast.setFailed': 'Failed: {error}',
        'toast.setError': 'Failed to set default app',
        'lang.switch': '中',
        'btn.batchReplace': 'Batch Replace',
        'batch.title': 'Batch Replace Default App',
        'batch.desc': 'Replace all file type associations from one app to another',
        'batch.sourceLabel': 'Replace from (current default app)',
        'batch.targetLabel': 'Replace to (new default app)',
        'batch.extCount': '{count} extensions',
        'batch.affectedExts': '{count} file extensions will be affected',
        'batch.selectSource': 'Please select a source app first',
        'batch.selectTarget': 'Please select a target app',
        'batch.noApps': 'No available target apps',
        'btn.batchConfirm': 'Confirm Replace',
        'batch.processing': 'Batch replacing...',
        'toast.batchSuccess': 'Batch replace done: {success} succeeded, {fail} failed',
        'toast.batchError': 'Batch replace failed',
        'batch.back': 'Back'
    }
}

/** 国际化 composable */
export function useI18n() {
    const t = computed(() => {
        const locale = currentLocale.value
        return (key: string, params?: Record<string, string>) => {
            let text = messages[locale]?.[key] ?? key
            if (params) {
                for (const [k, v] of Object.entries(params)) {
                    text = text.replace(`{${k}}`, v)
                }
            }
            return text
        }
    })

    const toggleLocale = () => {
        setLocale(currentLocale.value === 'zh-CN' ? 'en' : 'zh-CN')
    }

    return { t, currentLocale, toggleLocale }
}
