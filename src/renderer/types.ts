/** 单个应用信息 */
export interface AppInfo {
    name: string
    bundleId: string
}

/** 文件关联项 */
export interface FileAssocItem {
    ext: string
    uti: string
    defaultApp: AppInfo | null
    availableApps: AppInfo[]
}

/** 设置默认应用的结果 */
export interface SetResult {
    success: boolean
    error?: string
}

/** 批量设置的单项结果 */
export interface BatchSetResult {
    ext: string
    success: boolean
    error?: string
}

/** 文件关联 API 接口 */
export interface FileAssocAPI {
    list: () => Promise<FileAssocItem[]>
    query: (ext: string) => Promise<FileAssocItem | null>
    set: (ext: string, bundleId: string) => Promise<SetResult>
    batchSet: (extensions: string[], targetBundleId: string) => Promise<BatchSetResult[]>
}

declare global {
    interface Window {
        fileAssocAPI: FileAssocAPI
    }
}
