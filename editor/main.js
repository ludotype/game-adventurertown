const { app, BrowserWindow, Menu, dialog, ipcMain } = require('electron');
const path = require('path');

function createWindow () {
  const preloadPath = path.join(app.getAppPath(), 'preload.js');
  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });
  console.log('[main] preload path:', preloadPath);

  win.loadFile('index.html');
  win.setMenuBarVisibility(false);
  Menu.setApplicationMenu(null);
}

ipcMain.handle('open-folder-dialog', async () => {
  let win = BrowserWindow.getFocusedWindow() || BrowserWindow.getAllWindows()[0];
  if (!win || win.isDestroyed()) return { canceled: true };
  return await dialog.showOpenDialog(win, {
    properties: ['openDirectory'],
    title: 'Select data folder'
  });
});

ipcMain.handle('quit-app', async () => {
  app.quit();
});

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
