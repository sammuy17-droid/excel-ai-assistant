
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1100,
    height: 760,
    backgroundColor: "#0b1220",
    webPreferences: {
      contextIsolation: true,
    }
  });

  // If you deployed backend, set BACKEND_URL env var, e.g. https://your-app.onrender.com
  const backend = process.env.BACKEND_URL || "http://localhost:8000";
  const url = backend.replace(/\/$/,"") + "/web/index.html?api=" + encodeURIComponent(backend);
  win.loadURL(url);
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
