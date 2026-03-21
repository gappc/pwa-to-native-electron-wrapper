#!/usr/bin/env bash

set -e

ORIGINAL_PWD=$(pwd)
CONFIG_FILE="${1:-example.config}"

show_help() {
    echo "Usage: $0 [config_file]"
    echo ""
    echo "Reads configuration parameters from a file (defaults to 'config')."
    echo "The configuration file must contain the following mandatory variables:"
    echo "  APP_NAME=\"Your App Name\""
    echo "  APP_URL=\"https://example.com/\""
    echo "  FOLDER_NAME=\"your-app-folder\""
    echo ""
    echo "Optional variables:"
    echo "  ICON_FILE=\"path/to/icon.png\""
    echo "  START_ON_LOGIN=\"true|false\""
    echo "  INSTALL_AS_DESKTOP_APP=\"true|false\""
    echo "  INSTALL_DEPENDENCIES_AFTER_CREATION=\"true|false\""
    exit 1
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file '$CONFIG_FILE' not found."
    echo ""
    show_help
fi

# Load configuration
source "$CONFIG_FILE"

# Validate mandatory parameters
if [[ -z "$APP_NAME" || -z "$APP_URL" || -z "$FOLDER_NAME" ]]; then
    echo "Error: Missing mandatory parameters in '$CONFIG_FILE'."
    echo ""
    show_help
fi

# Resolve ICON_FILE path to absolute
if [[ -n "$ICON_FILE" && "$ICON_FILE" != /* ]]; then
    ICON_FILE="$(pwd)/$ICON_FILE"
fi

# Clean output folder if it exists
if [[ -d "app/$FOLDER_NAME" ]]; then
    echo "Cleaning existing output folder: app/$FOLDER_NAME"
    rm -rf "app/$FOLDER_NAME"
fi

echo "Creating project: app/$FOLDER_NAME"
mkdir -p "app/$FOLDER_NAME"
cd "app/$FOLDER_NAME"

# ---------------- package.json ----------------

cat <<EOF > package.json
{
  "name": "$FOLDER_NAME",
  "version": "1.0.0",
  "main": "main.js",
  "description": "Reusable PWA wrapper with tray support",
  "scripts": {
    "start": "electron . --no-sandbox"
  },
  "dependencies": {
    "electron": "^28.0.0"
  }
}
EOF

# ---------------- main.js ----------------

cat <<EOF > main.js
const { app, BrowserWindow, Tray, Menu } = require('electron');
const path = require('path');

let mainWindow;
let tray;

const APP_NAME = "$APP_NAME";
const APP_URL = "$APP_URL";

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1000,
    height: 800,
    show: false,
    icon: path.join(__dirname, 'icon.png'),
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js')
    }
  });

  mainWindow.setMenu(null);
  mainWindow.loadURL(APP_URL);

  mainWindow.on('page-title-updated', (event, title) => {
    // Many PWAs (like WhatsApp, Slack, Discord) format their title as "(X) App Name" 
    // when there are unread notifications.
    const match = title.match(/^\((\d+)\)/);
    if (match) {
      const unreadCount = parseInt(match[1], 10);
      if (tray) tray.setToolTip(\`$APP_NAME (\${unreadCount} unread)\`);
      if (app.setBadgeCount) app.setBadgeCount(unreadCount);
    } else {
      if (tray) tray.setToolTip(APP_NAME);
      if (app.setBadgeCount) app.setBadgeCount(0);
    }
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('close', (event) => {
    if (!app.isQuiting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });
}

function createTray() {
  tray = new Tray(path.join(__dirname, 'icon.png'));

  const contextMenu = Menu.buildFromTemplate([
    { label: APP_NAME, click: () => mainWindow.show() },
    { type: 'separator' },
    {
      label: 'Quit',
      click: () => {
        app.isQuiting = true;
        app.quit();
      }
    }
  ]);

  tray.setToolTip(APP_NAME);
  tray.setContextMenu(contextMenu);

  tray.on('click', () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
    }
  });
}

app.setName(APP_NAME);

const gotLock = app.requestSingleInstanceLock();

if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) mainWindow.show();
  });

  app.whenReady().then(() => {
    app.userAgentFallback = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

    createWindow();
    createTray();
  });
}

app.on('activate', () => {
  if (mainWindow) mainWindow.show();
});
EOF

# ---------------- preload.js ----------------

cat <<'EOF' > preload.js
// Empty preload (safe bridge placeholder)
EOF

# ---------------- icon.png ----------------

if [[ -n "$ICON_FILE" && -f "$ICON_FILE" ]]; then
    cp "$ICON_FILE" icon.png
else
    echo "No custom icon provided or file not found, creating empty icon.png"
    touch icon.png
fi

# ---------------- .desktop ----------------

APP_DIR="$(pwd)"
DESKTOP_FILE="${APP_NAME// /_}.desktop"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$APP_NAME
Exec=$APP_DIR/node_modules/electron/dist/electron $APP_DIR --no-sandbox
Terminal=false
Type=Application
Icon=$APP_DIR/icon.png
Categories=Network;WebBrowser;
EOF

# ---------------- README ----------------

cat <<EOF > README.md
# $APP_NAME - electron wrapper around $APP_URL

Next steps:

1. Install dependencies:
   npm install

2. Run the app:
   npm start

Optional (Desktop integration for launcher and badges):
To install the desktop shortcut so it appears in your launcher, run:

\`\`\`bash
mkdir -p ~/.local/share/applications/
cp "$DESKTOP_FILE" ~/.local/share/applications/
chmod +x ~/.local/share/applications/"$DESKTOP_FILE"
update-desktop-database ~/.local/share/applications/
\`\`\`

Then you can launch "$APP_NAME" directly from your app menu!

Optional (Autostart on login):

\`\`\`bash
mkdir -p ~/.config/autostart/
cp "$DESKTOP_FILE" ~/.config/autostart/
\`\`\`

Optional (GNOME tray support, not needed on newer Ubuntu versions):
sudo apt install gnome-shell-extension-appindicator

Config:

* APP_NAME: $APP_NAME
* APP_URL: $APP_URL
* START_ON_LOGIN: ${START_ON_LOGIN:-false}
* INSTALL_AS_DESKTOP_APP: ${INSTALL_AS_DESKTOP_APP:-false}
EOF

if [[ "$START_ON_LOGIN" == "true" ]]; then
    mkdir -p ~/.config/autostart/
    cp "$DESKTOP_FILE" ~/.config/autostart/
    echo "Autostart configured: the app will start automatically on login."
fi

if [[ "$INSTALL_AS_DESKTOP_APP" == "true" ]]; then
    mkdir -p ~/.local/share/applications/
    cp "$DESKTOP_FILE" ~/.local/share/applications/
    update-desktop-database ~/.local/share/applications/
    echo "Desktop shortcut installed: you can now launch '$APP_NAME' from your app menu."
fi

if [[ "$INSTALL_DEPENDENCIES_AFTER_CREATION" == "true" ]]; then
    echo "Installing dependencies..."
    npm install
fi

echo "Done!"
cd "$ORIGINAL_PWD"

echo "Now run:"
echo "  cd app/$FOLDER_NAME"
if [[ "$INSTALL_DEPENDENCIES_AFTER_CREATION" != "true" ]]; then
    echo "  npm install"
fi
echo "  npm start"
