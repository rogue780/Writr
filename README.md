# Writr

A Scrivener-compatible Android application built with Flutter that allows you to read, write, and manage Scrivener projects (.scrivx/.scriv) on your Android device with cloud storage integration.

## Features

### Scrivener Compatibility
- **Read/Write .scrivx Projects**: Full support for reading and writing Scrivener project files
- **Binder Navigation**: Hierarchical document organization with folder and document support
- **Document Editing**: Rich text editing with word and character count
- **Project Structure**: Maintains Scrivener's project structure including Files/Data directories

### Cloud Storage Integration (via Storage Access Framework)
- **Google Drive**: Access projects through the Google Drive app (if installed)
- **Dropbox**: Access projects through the Dropbox app (if installed)
- **OneDrive**: Access projects through the OneDrive app (if installed)
- **Local Storage**: Access projects from device storage
- **Any Cloud App**: Works with any cloud storage app that provides a document provider
- **No API Keys Required**: Uses Android's built-in file picker - no OAuth or API setup needed!

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

### Running the App

**Note**: No cloud storage configuration needed! The app uses Android's Storage Access Framework, which works with any installed cloud storage apps automatically.

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

1. **RTF Support**: Currently treats all documents as plain text
2. **Media Files**: Images and PDFs displayed but not editable
3. **Compile**: Scrivener's compile feature not yet implemented
4. **Cloud App Required**: To access cloud storage, you must have the respective app installed (Google Drive, Dropbox, etc.)

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
