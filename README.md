# PWA to Native Electron Wrapper

A simple bash scripting tool to generate native Electron desktop wrappers for Web Apps (PWAs). The generated applications behave like native apps with single-instance locking, system tray support, and unread notification badges.

## Features

- **Quick Generation**: Instantly scaffolds a complete Electron app configuration based on a single config file.
- **System Tray Support**: Apps minimize to the system tray and support right-click context menus.
- **Unread Notification Badges**: Monitors the web app's `<title>` for `(X)` notification counts (commonly used by WhatsApp, Slack, Discord) and automatically updates the Linux/system tray unread badge.
- **Single-instance Lock**: Ensures only one running instance of the app, focusing the window if an attempt is made to open a second instance.
- **Desktop Integration**: Automatically generates a Linux `.desktop` file for easy addition to your application launcher.

## Prerequisites

- `bash` (to run the script)
- `node` and `npm` (to install dependencies and run the generated app)

## Usage

1. **Create a configuration file**: Use `example.config` to model your own.
2. **Run the script**: Pass the config file as an argument.

```bash
./create-electron-pwa.sh <your-config-file>
```

*(If you run `./create-electron-pwa.sh` without arguments, it attempts to read `example.config` by default).*

3. **Install and Run**:
After the generation completes, the output will be placed in the `app/<FOLDER_NAME>` directory.

```bash
cd app/<FOLDER_NAME>
npm install
npm start
```

### Desktop Menu Integration (Linux)

To add the newly wrapped app to your application launcher (like GNOME/KDE Dash):

1. The script automatically generates a `.desktop` file in the output folder.
2. Copy it to your local applications directory:
   ```bash
   mkdir -p ~/.local/share/applications/
   cp app/<FOLDER_NAME>/*.desktop ~/.local/share/applications/
   update-desktop-database ~/.local/share/applications/
   ```

## Configuration File Structure

The project uses a simple bash-syntax configuration file. 

| Variable | Required | Description |
|---|---|---|
| `APP_NAME` | **Yes** | The display name of the application (e.g. `WhatsApp Web`). |
| `APP_URL` | **Yes** | The target URL to wrap within Electron. |
| `FOLDER_NAME` | **Yes** | The output subfolder name created within the `app/` directory. |
| `ICON_FILE` | *No* | Path to a `.png` file used for the system tray, launcher icon, and window icon. Relative paths are resolved against the current working directory. |
| `START_ON_LOGIN` | *No* | Set to `"true"` to automatically install the `.desktop` file to your `~/.config/autostart/` directory so the app launches silently on boot. |
| `START_MINIMIZED` | *No* | Set to `"true"` to start the app minimized to the system tray. |
| `INSTALL_AS_DESKTOP_APP`| *No* | Set to `"true"` to automatically install the `.desktop` file to your `~/.local/share/applications/` directory so the app appears in your system app launcher. |
| `INSTALL_DEPENDENCIES_AFTER_CREATION`| *No* | Set to `"true"` to automatically run `npm install` inside the generated application folder after creation. |

### Examples

**example.config**
```bash
APP_NAME="gappc.net"
APP_URL="https://gappc.net/"
FOLDER_NAME="gappc.net"
```

**whatsapp.config**
```bash
APP_NAME="WhatsApp Web"
APP_URL="https://web.whatsapp.com/"
FOLDER_NAME="whatsapp"
ICON_FILE="./whatsapp.png"
START_ON_LOGIN="true"
INSTALL_AS_DESKTOP_APP="true"
INSTALL_DEPENDENCIES_AFTER_CREATION="true"
```
