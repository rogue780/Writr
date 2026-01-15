# Writr

A cross-platform Scrivener-compatible application built with Flutter that allows you to read, write, and manage Scrivener projects (.scrivx/.scriv) on Android, Windows, macOS, and Linux with native file system integration.

## Supported Platforms

- 📱 **Android** (ARM64, ARM32, x86_64)
- 🪟 **Windows** (x64)
- 🍎 **macOS** (Intel & Apple Silicon)
- 🐧 **Linux** (x64)
- 🌐 **Web** (All browsers)

## Features

### Scrivener Compatibility
- **Read/Write .scrivx Projects**: Full support for reading and writing Scrivener project files
- **Binder Navigation**: Hierarchical document organization with folder and document support
- **Document Editing**: Rich text editing with word and character count
- **Project Structure**: Maintains Scrivener's project structure including Files/Data directories

### File System Integration

**Two Ways to Access Cloud Storage:**

1. **Native File Picker (Recommended - No Setup)**
   - Uses platform-native file dialogs
   - Works with installed cloud apps (Google Drive, Dropbox, OneDrive)
   - Access local storage, network drives, external drives
   - Zero configuration required

2. **Direct Cloud API Access (Optional - Requires Setup)**
   - Browse cloud files directly in the app
   - Google Drive, Dropbox, OneDrive integration
   - Requires one-time OAuth configuration
   - See [Cloud API Setup Guide](docs/CLOUD_API_SETUP.md)

### User Interface
- **Binder View**: Collapsible tree view for navigating your project structure
- **Document Editor**: Clean, distraction-free writing interface
- **Multi-pane Layout**: Toggle between binder and editor views
- **Material Design 3**: Modern, responsive UI following Material Design guidelines

## Getting Started

### Quick Start - Download Pre-built Binaries

#### 📱 Android APK

1. Go to the [Android Builds](../../actions/workflows/build-apk.yml)
2. Click on the latest successful workflow run
3. Scroll down to "Artifacts" section
4. Download `writr-release-*.apk` (recommended)
5. Extract the zip file
6. Enable "Install from Unknown Sources" on your Android device
7. Transfer the APK to your device and install

#### 🖥️ Desktop (Windows/macOS/Linux)

1. Go to the [Desktop Builds](../../actions/workflows/build-desktop.yml)
2. Click on the latest successful workflow run
3. Scroll down to "Artifacts" section
4. Download the appropriate build:
   - **Windows**: `writr-windows-*.zip` - Extract the entire zip and run `writr.exe` (keep `data/` next to it)
   - **macOS**: `writr-macos-*.zip` - Extract and move `writr.app` to Applications
   - **Linux**: `writr-linux-*.tar.gz` - Extract and run `./writr`

#### 🌐 Web Version (Try Online)

**Live Demo**: [https://rogue780.github.io/Writr/](https://rogue780.github.io/Writr/)

Try Writr instantly in your browser - no download or installation required!

**Note**: Web version has file system limitations. Projects are stored in browser storage. For full cloud integration, use the desktop or mobile apps.

### Prerequisites (For Building from Source)

- Flutter SDK (3.0.0 or higher)
- Git

**Platform-specific requirements:**
- **Android**: Android SDK (API level 21 or higher)
- **Windows**: Visual Studio 2022 with C++ desktop development
- **macOS**: Xcode 13 or higher
- **Linux**: GTK 3.0 development libraries

### Installation (Building from Source)

1. Clone the repository:
```bash
git clone https://github.com/rogue780/Writr.git
cd Writr
```

2. Install dependencies:
```bash
flutter pub get
```

### Cloud Storage Setup (Optional)

By default, Writr uses native file pickers - **no configuration needed!**

If you want to use **Direct Cloud API Access** (browse cloud files in-app):

1. See the [Cloud API Setup Guide](docs/CLOUD_API_SETUP.md) for detailed instructions
2. Configure OAuth credentials for:
   - Google Drive (Google Cloud Console)
   - Dropbox (Dropbox App Console)
   - OneDrive (Azure Portal)
3. Update provider files with your API keys/client IDs

**Note:** Most users won't need this - the native file picker works great and requires zero setup!

### Running and Building

#### Run in Development
```bash
# Android
flutter run

# Desktop (auto-detects your OS)
flutter run -d windows
flutter run -d macos
flutter run -d linux

# Web
flutter run -d chrome
```

#### Enable Desktop Platforms (First Time)
```bash
# Run the setup script
chmod +x setup_desktop.sh
./setup_desktop.sh

# PowerShell (Windows)
.\setup_desktop.ps1 -Platforms windows -PatchFilePicker

# Or manually:
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
flutter create --platforms=windows,macos,linux .
```

#### Build for Release
```bash
# Android
flutter build apk --release

# Windows
flutter build windows --release
# Output bundle:
# build/windows/x64/runner/Release/writr.exe

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── models/                            # Data models
│   └── scrivener_project.dart        # Scrivener project structure
├── services/                          # Business logic
│   ├── scrivener_service.dart        # Scrivener file handling
│   └── storage_access_service.dart   # Storage Access Framework integration
├── screens/                           # UI screens
│   ├── home_screen.dart              # Main landing screen
│   └── project_editor_screen.dart    # Project editing interface
└── widgets/                           # Reusable widgets
    ├── binder_tree_view.dart         # Hierarchical binder view
    └── document_editor.dart          # Text editing widget
```

## How It Works

### Scrivener File Format

Writr implements the Scrivener file format specification:

- **Project Structure**: `.scriv` packages contain the main `.scrivx` XML file
- **XML Parsing**: The `.scrivx` file is parsed to extract project structure
- **Binder Items**: Hierarchical organization of folders and documents
- **Text Storage**: Document content stored in `Files/Data/` directory
- **Metadata**: Project settings and document metadata preserved

### Storage Access Framework

Writr uses Android's Storage Access Framework (SAF) for seamless cloud integration:

1. **File Picker**: Tap "Open Project" to launch the system file picker
2. **Choose Location**: Select from any installed storage provider (Drive, Dropbox, OneDrive, etc.)
3. **Direct Access**: App accesses files directly through the provider
4. **No Setup Required**: Uses existing app authentication - no API keys or OAuth needed
5. **Automatic Sync**: Changes are saved directly to the chosen location

This approach provides:
- **Universal Compatibility**: Works with any cloud app that implements Android's document provider
- **Better Security**: No need to store OAuth tokens or API credentials
- **Native Experience**: Uses the familiar Android file picker interface
- **Simplified Setup**: Zero configuration required

## Features Roadmap

- [ ] RTF formatting support
- [ ] Snapshot management
- [ ] Labels and status indicators
- [ ] Compile/Export functionality
- [ ] Sync conflict resolution
- [ ] Offline mode with auto-sync
- [ ] Dark mode support
- [ ] Search functionality
- [ ] Import from various formats

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and delivery:

### Automatic Builds
Every push to `main` or `claude/**` branches triggers:
1. Code formatting verification
2. Static analysis with `flutter analyze`
3. Automated test suite
4. Multi-platform builds:
   - **Android**: APK (debug and release)
   - **Desktop**: Windows, macOS, Linux
   - **Web**: Deployed to GitHub Pages
5. Artifacts uploaded for 90 days

### Manual Builds
You can trigger a manual build anytime:
1. Go to Actions > "Manual Build APK"
2. Click "Run workflow"
3. Choose build type (debug/release/both)
4. Download from artifacts

### Workflow Files
- `.github/workflows/build-apk.yml` - Android CI/CD pipeline
- `.github/workflows/build-desktop.yml` - Desktop builds (Windows/macOS/Linux)
- `.github/workflows/build-web.yml` - Web build and GitHub Pages deployment
- `.github/workflows/manual-build.yml` - Manual build trigger

## Known Limitations

1. **RTF Support**: Currently treats all documents as plain text
2. **Media Files**: Images and PDFs displayed but not editable
3. **Compile**: Scrivener's compile feature not yet implemented
4. **Cloud Storage Access**:
   - **Native file picker**: Requires cloud apps installed (Google Drive, Dropbox, etc.)
   - **Direct API access**: Requires OAuth setup (optional, see docs)
5. **Web File System**: Web version uses browser storage with limited file system access. Desktop/mobile apps recommended for full functionality
6. **OAuth Flow**: Cloud API authentication currently requires manual token handling. Consider using flutter_web_auth for production (see setup guide)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Push and create a PR
5. GitHub Actions will automatically build and test your changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

Writr is an independent project and is not officially affiliated with or endorsed by Literature & Latte, the creators of Scrivener. Scrivener is a trademark of Literature & Latte Ltd.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## Acknowledgments

- Flutter team for the excellent framework
- Scrivener community for inspiration
- Open source contributors
