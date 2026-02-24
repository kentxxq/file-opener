import { app, BrowserWindow, ipcMain } from 'electron'
import path from 'path'
import { execFile } from 'child_process'
import { promisify } from 'util'

const execFileAsync = promisify(execFile)

/**
 * 获取原生 helper 工具的路径
 * 打包后从 resources 目录加载，开发时从项目 resources 目录加载
 */
function getHelperPath(): string {
    if (app.isPackaged) {
        return path.join(process.resourcesPath, 'file-assoc-helper')
    }
    return path.join(__dirname, '../../resources/file-assoc-helper')
}

/**
 * 执行原生 helper 命令
 */
async function runHelper(...args: string[]): Promise<string> {
    const helperPath = getHelperPath()
    const { stdout } = await execFileAsync(helperPath, args, { timeout: 15000 })
    return stdout.trim()
}

/**
 * 注册 IPC 处理器，提供文件关联的增删改查能力
 */
function registerIpcHandlers(): void {
    // 列出所有文件后缀的默认应用和可选应用
    ipcMain.handle('file-assoc:list', async () => {
        try {
            const result = await runHelper('list')
            return JSON.parse(result)
        } catch (error) {
            console.error('list error:', error)
            return []
        }
    })

    // 查询指定后缀的详细信息
    ipcMain.handle('file-assoc:query', async (_event, ext: string) => {
        try {
            const safeExt = ext.replace(/[^a-zA-Z0-9]/g, '')
            const result = await runHelper('query', safeExt)
            return JSON.parse(result)
        } catch (error) {
            console.error('query error:', error)
            return null
        }
    })

    // 设置指定后缀的默认应用
    ipcMain.handle('file-assoc:set', async (_event, ext: string, bundleId: string) => {
        try {
            const safeExt = ext.replace(/[^a-zA-Z0-9]/g, '')
            const safeBundleId = bundleId.replace(/[^a-zA-Z0-9.\-]/g, '')
            const result = await runHelper('set', safeExt, safeBundleId)
            return JSON.parse(result)
        } catch (error) {
            console.error('set error:', error)
            return { success: false, error: String(error) }
        }
    })

    // 批量设置：将多个后缀的默认应用替换为目标应用
    ipcMain.handle('file-assoc:batch-set', async (_event, extensions: string[], targetBundleId: string) => {
        const safeBundleId = targetBundleId.replace(/[^a-zA-Z0-9.\-]/g, '')
        const results: Array<{ ext: string; success: boolean; error?: string }> = []
        for (const ext of extensions) {
            try {
                const safeExt = ext.replace(/[^a-zA-Z0-9]/g, '')
                const result = await runHelper('set', safeExt, safeBundleId)
                results.push({ ext, ...JSON.parse(result) })
            } catch (error) {
                console.error(`batch-set error for ${ext}:`, error)
                results.push({ ext, success: false, error: String(error) })
            }
        }
        return results
    })
}

/**
 * 创建主窗口
 */
function createWindow(): void {
    const mainWindow = new BrowserWindow({
        width: 960,
        height: 700,
        minWidth: 700,
        minHeight: 500,
        titleBarStyle: 'hiddenInset',
        trafficLightPosition: { x: 16, y: 16 },
        backgroundColor: '#0f0f14',
        webPreferences: {
            preload: path.join(__dirname, '../preload/index.js'),
            sandbox: false
        }
    })

    // 开发环境加载 dev server，生产环境加载本地文件
    if (process.env['ELECTRON_RENDERER_URL']) {
        mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
    } else {
        mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'))
    }
}

app.whenReady().then(() => {
    registerIpcHandlers()
    createWindow()

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow()
        }
    })
})

app.on('window-all-closed', () => {
    app.quit()
})
