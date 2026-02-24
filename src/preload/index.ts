import { contextBridge, ipcRenderer } from 'electron'

/** 暴露给渲染进程的文件关联 API */
contextBridge.exposeInMainWorld('fileAssocAPI', {
    /** 列出所有文件后缀的默认应用和可选应用 */
    list: () => ipcRenderer.invoke('file-assoc:list'),
    /** 查询指定后缀的详细信息 */
    query: (ext: string) => ipcRenderer.invoke('file-assoc:query', ext),
    /** 设置指定后缀的默认应用 */
    set: (ext: string, bundleId: string) => ipcRenderer.invoke('file-assoc:set', ext, bundleId),
    /** 批量设置：将多个后缀的默认应用替换为目标应用 */
    batchSet: (extensions: string[], targetBundleId: string) => ipcRenderer.invoke('file-assoc:batch-set', extensions, targetBundleId)
})
