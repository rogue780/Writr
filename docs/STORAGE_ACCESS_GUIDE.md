# Storage Access Framework Guide

## Overview

Writr uses Android's Storage Access Framework (SAF) to access files from any storage location, including cloud storage providers. This means you don't need to set up API keys or authenticate separately - the app uses the cloud storage apps you already have installed.

## Supported Storage Providers

### ✅ Works with any app that provides a document provider:

- **Google Drive** (requires Google Drive app)
- **Dropbox** (requires Dropbox app)
- **OneDrive** (requires OneDrive app)
- **Samsung My Files**
- **Solid Explorer**
- **Any other file manager or cloud storage app**

## How to Use

### Opening a Project

1. **Tap "Open Project"** on the home screen
2. **The Android file picker will appear** showing all available storage locations
3. **Navigate to your .scriv folder**:
   - For Google Drive: Tap "Drive" in the sidebar
   - For Dropbox: Tap "Dropbox" in the sidebar
   - For OneDrive: Tap "OneDrive" in the sidebar
   - For local storage: Tap "Internal storage" or "SD card"
4. **Select the .scriv folder** (the entire project folder, not individual files inside)
5. **Grant permission** if prompted
6. **The project will open** in the editor

### Creating a New Project

1. **Tap "Create New Project"**
2. **Enter a project name**
3. **Choose where to save it** using the file picker
4. **The new project will be created** and opened

### Permissions

When you select a file or folder, Android will ask for permission to access it. These permissions are:
- **Read access**: Required to open and view projects
- **Write access**: Required to save changes
- **Persistent access**: Allows the app to remember the location

The app only has access to the specific folders you select - it cannot access your entire cloud storage.

## Benefits of Storage Access Framework

### 🔐 Security
- No API keys stored in the app
- No OAuth tokens to manage
- Only access to folders you explicitly select
- Leverages existing app authentication

### 🚀 Simplicity
- Zero configuration required
- Works immediately after installing
- No account linking needed
- Familiar Android file picker interface

### 🌍 Universal Compatibility
- Works with any cloud storage app
- Supports multiple providers simultaneously
- No vendor lock-in
- Future-proof architecture

### ⚡ Performance
- Direct file access (no downloading/uploading)
- Changes saved immediately
- Efficient syncing handled by cloud apps
- Works offline with local files

## Limitations

### 📱 App Installation Required
To access cloud storage, you must have the respective app installed:
- For Google Drive access, install Google Drive app
- For Dropbox access, install Dropbox app
- For OneDrive access, install OneDrive app

### 📂 Folder Permissions
Some cloud storage apps may have limitations on folder access. If you encounter issues:
1. Make sure the cloud storage app is up to date
2. Try moving the project to a different folder
3. Check the cloud app's settings for file access permissions

### 🔄 Sync Timing
Changes are saved immediately, but syncing to the cloud depends on:
- Your internet connection
- The cloud storage app's sync settings
- Available device storage

## Troubleshooting

### "Cannot find .scriv folder"
- Make sure you've selected the entire .scriv folder, not files inside it
- Check that the folder is properly synced to your device
- Try refreshing the cloud storage app

### "Permission denied"
- Grant all requested permissions when prompted
- Check Android Settings > Apps > Writr > Permissions
- Ensure the cloud storage app has necessary permissions

### "Project won't open"
- Verify the .scriv folder structure is intact
- Check that the .scrivx file exists inside the folder
- Try copying the project to local storage first

### "Changes not syncing"
- Check your internet connection
- Open the cloud storage app to force a sync
- Verify you have available cloud storage space
- Check the cloud app's sync settings

## Best Practices

### ✅ Do:
- Keep cloud storage apps updated
- Regularly check sync status
- Test opening projects before editing
- Keep backups of important projects
- Use local storage for active editing (faster)

### ❌ Don't:
- Edit the same project on multiple devices simultaneously
- Delete projects from within the cloud app while open in Writr
- Modify project files outside of Writr
- Ignore sync warnings from cloud apps

## Technical Details

### How SAF Works
1. App requests file access through Android system
2. System shows picker with all available document providers
3. User selects file/folder from any provider
4. System grants URI-based permissions to the app
5. App reads/writes through content resolver
6. Changes sync automatically via the provider app

### Supported Operations
- ✅ Open existing .scriv projects
- ✅ Create new projects
- ✅ Read document contents
- ✅ Write document changes
- ✅ Modify project structure
- ✅ Save project metadata

### File System Access
The app accesses files using Android's content:// URIs rather than direct file paths. This provides:
- Secure, sandboxed access
- Provider-agnostic operations
- Automatic permission management
- System-level integration

## Additional Resources

- [Android Storage Access Framework Documentation](https://developer.android.com/guide/topics/providers/document-provider)
- [Scrivener File Format Specification](https://www.literatureandlatte.com/scrivener/overview)
- [Writr GitHub Repository](https://github.com/rogue780/Writr)

## Support

If you encounter issues with storage access:
1. Check this guide's troubleshooting section
2. Verify cloud storage app is working properly
3. Open an issue on GitHub with details
4. Include Android version and device model
