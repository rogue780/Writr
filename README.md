# Writr

A Scrivener-compatible Android application built with Flutter that allows you to read, write, and manage Scrivener projects (.scrivx/.scriv) on your Android device with cloud storage integration.

## Features

### Scrivener Compatibility
- **Read/Write .scrivx Projects**: Full support for reading and writing Scrivener project files
- **Binder Navigation**: Hierarchical document organization with folder and document support
- **Document Editing**: Rich text editing with word and character count
- **Project Structure**: Maintains Scrivener's project structure including Files/Data directories

### Cloud Storage Integration
- **Google Drive**: Seamlessly access and save projects to Google Drive
- **Dropbox**: Full integration with Dropbox for project storage
- **OneDrive**: Microsoft OneDrive support for cloud-based projects
- **Local Storage**: Store and access projects on your device

### User Interface
- **Binder View**: Collapsible tree view for navigating your project structure
- **Document Editor**: Clean, distraction-free writing interface
- **Multi-pane Layout**: Toggle between binder and editor views
- **Material Design 3**: Modern, responsive UI following Material Design guidelines

## Getting Started

### Quick Start - Download Pre-built APK

Don't want to build from source? Download the latest APK directly from GitHub Actions:

1. Go to the [Actions tab](../../actions/workflows/build-apk.yml)
2. Click on the latest successful workflow run
3. Scroll down to "Artifacts" section
4. Download either:
   - `writr-debug-*.apk` - Debug build with more logging
   - `writr-release-*.apk` - Optimized release build (recommended)
5. Extract the zip file
6. Enable "Install from Unknown Sources" on your Android device
7. Transfer the APK to your device and install

### Prerequisites (For Building from Source)

- Flutter SDK (3.0.0 or higher)
- Android SDK (API level 21 or higher)
- Git

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

3. Configure Cloud Storage (Optional):

#### Google Drive
1. Create a project in [Google Cloud Console](https://console.cloud.google.com)
2. Enable Google Drive API
3. Create OAuth 2.0 credentials
4. Add credentials to your app

#### Dropbox
1. Create an app in [Dropbox App Console](https://www.dropbox.com/developers/apps)
2. Get your App Key
3. Update `_appKey` in `lib/services/cloud/dropbox_provider.dart`

#### OneDrive
1. Register your app in [Microsoft Azure Portal](https://portal.azure.com)
2. Get your Client ID
3. Update `_clientId` in `lib/services/cloud/onedrive_provider.dart`

### Running the App

```bash
flutter run
```

To build for release:
```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── models/                            # Data models
│   ├── scrivener_project.dart        # Scrivener project structure
│   └── cloud_storage.dart            # Cloud storage models
├── services/                          # Business logic
│   ├── scrivener_service.dart        # Scrivener file handling
│   ├── cloud_storage_service.dart    # Cloud storage abstraction
│   └── cloud/                        # Cloud provider implementations
│       ├── google_drive_provider.dart
│       ├── dropbox_provider.dart
│       └── onedrive_provider.dart
├── screens/                           # UI screens
│   ├── home_screen.dart              # Main landing screen
│   ├── cloud_browser_screen.dart     # Cloud file browser
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

### Cloud Storage Flow

1. **Authentication**: OAuth 2.0 flow for each cloud provider
2. **File Browsing**: List and navigate cloud storage directories
3. **Download**: Projects downloaded to temporary storage for editing
4. **Sync**: Modified projects uploaded back to cloud storage

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
4. APK builds (both debug and release)
5. Artifacts uploaded for 30-90 days

### Manual Builds
You can trigger a manual build anytime:
1. Go to Actions > "Manual Build APK"
2. Click "Run workflow"
3. Choose build type (debug/release/both)
4. Download from artifacts

### Workflow Files
- `.github/workflows/build-apk.yml` - Automatic CI/CD pipeline
- `.github/workflows/manual-build.yml` - Manual build trigger

## Known Limitations

1. **Authentication**: Cloud storage OAuth flows require additional setup
2. **RTF Support**: Currently treats all documents as plain text
3. **Media Files**: Images and PDFs displayed but not editable
4. **Compile**: Scrivener's compile feature not yet implemented

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
