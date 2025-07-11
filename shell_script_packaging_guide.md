# How to Package Shell Scripts as Applications

This guide covers various methods to convert shell scripts into distributable applications across different platforms.

## Table of Contents

1. [macOS Applications](#macos-applications)
2. [Linux Applications](#linux-applications)
3. [Cross-Platform Solutions](#cross-platform-solutions)
4. [Self-Extracting Archives](#self-extracting-archives)
5. [GUI Wrappers](#gui-wrappers)
6. [Considerations](#considerations)

---

## macOS Applications

### 1. Platypus (Recommended for macOS)

**Platypus** is the most comprehensive tool for creating native macOS applications from shell scripts.

**Features:**
- Full GUI interface for configuration
- Multiple interface types (progress bar, text output, droplet, etc.)
- Built-in script editor
- Custom icons and file type associations
- Command-line tool for automation
- Supports multiple scripting languages

**Installation:**
```bash
# Via Homebrew
brew install --cask platypus

# Or download from: https://sveinbjorn.org/platypus
```

**Usage:**
1. Open Platypus application
2. Select script file and configure options
3. Choose interface type and appearance
4. Set application name, icon, and bundle identifier
5. Click "Create App"

**Command Line Usage:**
```bash
# Create app from command line
platypus -a 'MyApp' -o 'Progress Bar' -i '/path/to/icon.icns' -u 'Author Name' -V '1.0' -s 'signature' /path/to/script.sh
```

### 2. Appify (Simple macOS Apps)

**Appify** creates basic macOS application bundles from shell scripts.

**Installation:**
```bash
# Via npm
npm install -g mac-appify

# Via pip
pip install mac-appify
```

**Usage:**
```bash
# Basic usage
appify script.sh MyApp.app

# With custom icon
appify script.sh MyApp.app icon.png
```

**Manual appify approach:**
```bash
#!/usr/bin/env bash
APPNAME=${1:-Untitled}

mkdir -p "$APPNAME.app/Contents/MacOS"
touch "$APPNAME.app/Contents/MacOS/$APPNAME"
chmod +x "$APPNAME.app/Contents/MacOS/$APPNAME"

# Copy script content to app
cat > "$APPNAME.app/Contents/MacOS/$APPNAME" << 'EOF'
#!/bin/bash
# Your script content here
EOF

echo "Created: $PWD/$APPNAME.app"
```

### 3. Manual .app Bundle Creation

For full control, create the bundle structure manually:

```bash
# Create app structure
mkdir -p "MyApp.app/Contents/MacOS"
mkdir -p "MyApp.app/Contents/Resources"

# Create executable
cp myscript.sh "MyApp.app/Contents/MacOS/MyApp"
chmod +x "MyApp.app/Contents/MacOS/MyApp"

# Create Info.plist
cat > "MyApp.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MyApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.myapp</string>
    <key>CFBundleName</key>
    <string>MyApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
```

---

## Linux Applications

### 1. AppImage (Recommended for Linux)

**AppImage** creates portable Linux applications that run on most distributions.

**Requirements:**
- Download `appimagetool` from AppImage releases
- Create proper directory structure

**Process:**
```bash
# Download appimagetool
ARCH="x86_64"
curl -L -o appimagetool-$ARCH.AppImage \
  https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage
chmod +x appimagetool-$ARCH.AppImage

# Create app directory structure
mkdir -p myapp.AppDir/usr/bin
mkdir -p myapp.AppDir/usr/share/applications
mkdir -p myapp.AppDir/usr/share/icons/hicolor/256x256/apps

# Copy script to app directory
cp myscript.sh myapp.AppDir/usr/bin/myapp
chmod +x myapp.AppDir/usr/bin/myapp

# Create AppRun (entry point)
cat > myapp.AppDir/AppRun << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
exec usr/bin/myapp "$@"
EOF
chmod +x myapp.AppDir/AppRun

# Create desktop file
cat > myapp.AppDir/usr/share/applications/myapp.desktop << 'EOF'
[Desktop Entry]
Name=MyApp
Exec=myapp
Icon=myapp
Type=Application
Categories=Utility
EOF

# Create AppImage
./appimagetool-$ARCH.AppImage myapp.AppDir
```

### 2. Debian Package (.deb)

Create a proper Debian package for your shell script:

```bash
# Create package structure
mkdir -p myapp-1.0/DEBIAN
mkdir -p myapp-1.0/usr/local/bin
mkdir -p myapp-1.0/usr/share/applications

# Copy script
cp myscript.sh myapp-1.0/usr/local/bin/myapp
chmod +x myapp-1.0/usr/local/bin/myapp

# Create control file
cat > myapp-1.0/DEBIAN/control << 'EOF'
Package: myapp
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Depends: bash
Maintainer: Your Name <your.email@example.com>
Description: My shell script application
 A longer description of what the application does.
EOF

# Create desktop entry
cat > myapp-1.0/usr/share/applications/myapp.desktop << 'EOF'
[Desktop Entry]
Name=MyApp
Exec=/usr/local/bin/myapp
Type=Application
Categories=Utility
EOF

# Build package
dpkg-deb --build myapp-1.0
```

### 3. RPM Package

For Red Hat-based systems:

```bash
# Create RPM spec file
cat > myapp.spec << 'EOF'
Name: myapp
Version: 1.0
Release: 1
Summary: My shell script application
License: MIT
BuildArch: noarch
Requires: bash

%description
A shell script application packaged as RPM.

%prep
%setup -q

%install
mkdir -p %{buildroot}/usr/local/bin
install -m 755 myscript.sh %{buildroot}/usr/local/bin/myapp

%files
/usr/local/bin/myapp

%changelog
* Wed Oct 01 2024 Your Name <your.email@example.com> - 1.0-1
- Initial package
EOF

# Build RPM
rpmbuild -ba myapp.spec
```

---

## Cross-Platform Solutions

### 1. Electron Wrapper

Create a cross-platform GUI app using Electron:

```bash
# Create Electron app structure
mkdir electron-shell-app
cd electron-shell-app

# Initialize npm project
npm init -y

# Install Electron
npm install --save-dev electron

# Create main.js
cat > main.js << 'EOF'
const { app, BrowserWindow } = require('electron');
const { spawn } = require('child_process');

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.loadFile('index.html');
}

app.whenReady().then(createWindow);
EOF

# Create index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Shell Script App</title>
</head>
<body>
    <h1>My Shell Script Application</h1>
    <button onclick="runScript()">Run Script</button>
    <pre id="output"></pre>
    
    <script>
        function runScript() {
            const { spawn } = require('child_process');
            const script = spawn('bash', ['script.sh']);
            
            script.stdout.on('data', (data) => {
                document.getElementById('output').textContent += data;
            });
        }
    </script>
</body>
</html>
EOF

# Add start script to package.json
npm pkg set scripts.start="electron ."
```

### 2. Web-Based Application

Create a web interface for your shell script:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Shell Script Web App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        button { padding: 10px 20px; font-size: 16px; }
        #output { background: #f0f0f0; padding: 10px; margin-top: 10px; }
    </style>
</head>
<body>
    <h1>My Shell Script Application</h1>
    <button onclick="runScript()">Execute Script</button>
    <div id="output"></div>
    
    <script>
        async function runScript() {
            try {
                const response = await fetch('/run-script', { method: 'POST' });
                const result = await response.text();
                document.getElementById('output').textContent = result;
            } catch (error) {
                document.getElementById('output').textContent = 'Error: ' + error.message;
            }
        }
    </script>
</body>
</html>
```

---

## Self-Extracting Archives

### 1. Makeself (Recommended)

**Makeself** creates self-extracting archives that can include installation scripts:

**Installation:**
```bash
# Download makeself
wget https://github.com/megastep/makeself/releases/download/release-2.5.0/makeself-2.5.0.run
chmod +x makeself-2.5.0.run
./makeself-2.5.0.run
```

**Usage:**
```bash
# Create directory with files to package
mkdir myapp
cp myscript.sh myapp/
cp -r additional_files/ myapp/

# Create installation script
cat > myapp/install.sh << 'EOF'
#!/bin/bash
echo "Installing MyApp..."
cp myscript.sh /usr/local/bin/myapp
chmod +x /usr/local/bin/myapp
echo "Installation complete!"
EOF

chmod +x myapp/install.sh

# Create self-extracting installer
./makeself.sh myapp myapp-installer.run "MyApp Installer" ./install.sh
```

### 2. Simple Self-Extractor

Create a basic self-extracting script:

```bash
#!/bin/bash
# Self-extracting installer template

ARCHIVE_START_LINE=20
TEMP_DIR=$(mktemp -d)

# Extract archive
tail -n +$ARCHIVE_START_LINE "$0" | tar -xz -C "$TEMP_DIR"

# Run installation
cd "$TEMP_DIR"
./install.sh

# Cleanup
rm -rf "$TEMP_DIR"
exit 0

# Archive begins here
EOF
tar -czf - myapp/ >> installer.sh
```

---

## GUI Wrappers

### 1. Zenity (Linux/Unix)

Add GUI dialogs to shell scripts:

```bash
#!/bin/bash
# Script with GUI elements

# File selection dialog
FILE=$(zenity --file-selection --title="Select a file")

# Progress dialog
(
    echo "0"
    echo "# Starting process..."
    sleep 1
    echo "50"
    echo "# Half way done..."
    sleep 1
    echo "100"
    echo "# Complete!"
) | zenity --progress --title="Processing" --auto-close

# Information dialog
zenity --info --text="Process completed successfully!"
```

### 2. Dialog/Whiptail (Terminal UI)

Create text-based user interfaces:

```bash
#!/bin/bash
# Terminal UI script

# Menu selection
CHOICE=$(dialog --menu "Choose an option:" 15 50 4 \
    1 "Option 1" \
    2 "Option 2" \
    3 "Option 3" \
    4 "Exit" 2>&1 >/dev/tty)

case $CHOICE in
    1) echo "You selected Option 1" ;;
    2) echo "You selected Option 2" ;;
    3) echo "You selected Option 3" ;;
    4) exit 0 ;;
esac
```

### 3. AppleScript Integration (macOS)

Add native macOS dialogs:

```bash
#!/bin/bash
# macOS script with native dialogs

# Display dialog
RESULT=$(osascript -e 'display dialog "Enter your name:" default answer ""' -e 'text returned of result')

# Display notification
osascript -e "display notification \"Hello, $RESULT!\" with title \"Greeting\""
```

---

## Considerations

### Security
- **Code Signing**: Sign your applications for distribution
- **Permissions**: Ensure scripts have appropriate permissions
- **Sandboxing**: Consider security implications of shell access

### Distribution
- **Dependencies**: Document required system dependencies
- **Version Control**: Include version information
- **Updates**: Plan for application updates

### User Experience
- **Error Handling**: Implement proper error handling
- **Progress Feedback**: Show progress for long-running operations
- **Documentation**: Include help/documentation

### Platform-Specific Notes

**macOS:**
- Applications may require notarization for distribution
- Consider Gatekeeper requirements
- Use proper bundle identifiers

**Linux:**
- Test across different distributions
- Consider package manager integration
- Handle different desktop environments

**Cross-Platform:**
- Use portable shell constructs
- Test on target platforms
- Consider different file system conventions

---

## Examples and Templates

### Basic Application Template

```bash
#!/bin/bash
# Application template with proper structure

set -euo pipefail

# Configuration
APP_NAME="MyApp"
APP_VERSION="1.0.0"
APP_AUTHOR="Your Name"

# Functions
show_help() {
    cat << EOF
$APP_NAME v$APP_VERSION

Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help message
    -v, --version   Show version information
    
Examples:
    $0 --help
    $0 --version
EOF
}

show_version() {
    echo "$APP_NAME v$APP_VERSION by $APP_AUTHOR"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help >&2
                exit 1
                ;;
        esac
    done
    
    # Main application logic here
    echo "Hello from $APP_NAME!"
}

# Run main function
main "$@"
```

This guide provides comprehensive coverage of different approaches to packaging shell scripts as applications. Choose the method that best fits your target platform and distribution requirements.