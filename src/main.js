const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');

// --- Auto Updater 설정 ---
// 로그 활성화 (디버깅용)
autoUpdater.logger = require('electron-updater').autoUpdater.logger;
if (autoUpdater.logger) {
  autoUpdater.logger.transports = undefined;
}

// 자동 다운로드 비활성화 → 사용자에게 알림 후 수동 트리거 가능
autoUpdater.autoDownload = false;
autoUpdater.autoInstallOnAppQuit = true;

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));
}

// --- Auto Updater 이벤트 핸들러 ---
autoUpdater.on('checking-for-update', () => {
  sendToRenderer('update-status', '업데이트 확인 중...');
});

autoUpdater.on('update-available', (info) => {
  sendToRenderer('update-status', `새 버전 발견: v${info.version}`);
  sendToRenderer('update-available', {
    version: info.version,
    releaseDate: info.releaseDate,
    releaseNotes: info.releaseNotes,
  });
});

autoUpdater.on('update-not-available', (info) => {
  sendToRenderer('update-status', `현재 최신 버전입니다 (v${info.version})`);
});

autoUpdater.on('download-progress', (progress) => {
  sendToRenderer('update-status',
    `다운로드 중... ${Math.round(progress.percent)}% (${formatBytes(progress.transferred)}/${formatBytes(progress.total)})`
  );
  sendToRenderer('download-progress', {
    percent: progress.percent,
    transferred: progress.transferred,
    total: progress.total,
    bytesPerSecond: progress.bytesPerSecond,
  });
});

autoUpdater.on('update-downloaded', (info) => {
  sendToRenderer('update-status', `v${info.version} 다운로드 완료! 재시작하면 적용됩니다.`);
  sendToRenderer('update-downloaded', { version: info.version });
});

autoUpdater.on('error', (err) => {
  sendToRenderer('update-status', `업데이트 오류: ${err.message}`);
  sendToRenderer('update-error', { message: err.message });
});

// --- IPC 핸들러 ---
ipcMain.handle('check-for-updates', async () => {
  try {
    const result = await autoUpdater.checkForUpdates();
    return { success: true, result };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('download-update', async () => {
  try {
    await autoUpdater.downloadUpdate();
    return { success: true };
  } catch (err) {
    return { success: false, error: err.message };
  }
});

ipcMain.handle('install-update', () => {
  autoUpdater.quitAndInstall();
});

ipcMain.handle('get-app-version', () => {
  return app.getVersion();
});

// --- 유틸 함수 ---
function sendToRenderer(channel, data) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, data);
  }
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

// --- 앱 시작 ---
app.whenReady().then(() => {
  createWindow();

  // 앱 시작 후 3초 뒤 자동으로 업데이트 확인
  setTimeout(() => {
    autoUpdater.checkForUpdates().catch((err) => {
      console.error('Auto update check failed:', err.message);
    });
  }, 3000);
});

app.on('window-all-closed', () => {
  app.quit();
});
