const { contextBridge, ipcRenderer } = require('electron');
const fs = require('fs');
const path = require('path');

contextBridge.exposeInMainWorld('electronAPI', {
  readDir: (dirPath) => {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    return entries.map(d => ({ name: d.name, isDirectory: d.isDirectory() }));
  },
  readFile: (filePath) => fs.readFileSync(filePath, 'utf-8'),
  writeFile: (filePath, content) => fs.writeFileSync(filePath, content, 'utf-8'),
  joinPath: (...args) => path.join(...args),
  resolvePath: (relative) => path.resolve(relative),
  pathDirname: (p) => path.dirname(p),
  pathBasename: (p) => path.basename(p),
  openFolderDialog: () => ipcRenderer.invoke('open-folder-dialog'),
  quit: () => ipcRenderer.invoke('quit-app'),
  onSelectFolder: (callback) => ipcRenderer.on('select-folder', (event, folderPath) => callback(folderPath))
});
