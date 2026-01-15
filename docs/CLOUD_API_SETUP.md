# Cloud Storage API Setup Guide

This guide explains how to configure Writr to use direct cloud storage API access for Google Drive, Dropbox, and OneDrive.

## Why Use Cloud APIs?

Writr offers two methods for accessing cloud storage:

1. **Native File Picker (Recommended)** - Uses Storage Access Framework (SAF)
   - No configuration required
   - Works with any installed cloud app
   - Simple and secure

2. **Direct Cloud API Access** - Uses OAuth and cloud provider APIs
   - Browse files directly from the app
   - No need to have cloud apps installed
   - Requires one-time API setup

## Prerequisites

- A Google, Dropbox, or Microsoft account
- Access to the respective developer console
- Basic understanding of OAuth 2.0 (helpful but not required)

---

## Google Drive API Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Create Project"
3. Name it "Writr" (or any name you prefer)
4. Click "Create"

### Step 2: Enable Google Drive API

1. In your project, go to "APIs & Services" > "Library"
2. Search for "Google Drive API"
3. Click on it and press "Enable"

### Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" (unless you have a Google Workspace account)
3. Click "Create"
4. Fill in the required information:
   - App name: `Writr`
   - User support email: Your email
   - Developer contact email: Your email
5. Click "Save and Continue"
6. Click "Add or Remove Scopes"
7. Add the scope: `https://www.googleapis.com/auth/drive.file`
8. Click "Update" then "Save and Continue"
9. Add yourself as a test user
10. Click "Save and Continue"

### Step 4: Create OAuth Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android" as the application type
4. Name: `Writr Android`
5. Package name: `com.example.writr` (or your custom package name)
6. For the SHA-1 certificate fingerprint:
   ```bash
   # Debug certificate (for development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
7. Copy the SHA-1 fingerprint and paste it
8. Click "Create"

**Note:** For release builds, you'll need to create another OAuth client ID with your release keystore's SHA-1.

### Step 5: No Code Changes Needed!

Google Sign-In automatically discovers the credentials through your package name and SHA-1 certificate. The existing code will work once the above setup is complete.

---

## Dropbox API Setup

### Step 1: Create a Dropbox App

1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps)
2. Click "Create app"
3. Choose:
   - API: Scoped access
   - Access type: Full Dropbox
   - Name: `Writr`
4. Click "Create app"

### Step 2: Configure Permissions

1. In your app settings, go to the "Permissions" tab
2. Enable the following scopes:
   - `files.metadata.write`
   - `files.metadata.read`
   - `files.content.write`
   - `files.content.read`
3. Click "Submit"

### Step 3: Get Your App Key

1. Go to the "Settings" tab
2. Copy your "App key"

### Step 4: Update the Code

Open `lib/services/dropbox_provider.dart` and replace:

```dart
static const String _appKey = 'YOUR_DROPBOX_APP_KEY';
```

with:

```dart
static const String _appKey = 'your_actual_app_key_here';
```

### Step 5: Configure Redirect URI

1. In the Dropbox app settings, find "Redirect URIs"
2. Add: `writr://oauth2redirect`
3. Click "Add"

### Step 6: Configure Android Manifest

Add to `android/app/src/main/AndroidManifest.xml` inside the `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="writr" android:host="oauth2redirect" />
</intent-filter>
```

---

## OneDrive API Setup

### Step 1: Register an Application

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to "Azure Active Directory" > "App registrations"
3. Click "New registration"
4. Fill in:
   - Name: `Writr`
   - Supported account types: "Accounts in any organizational directory and personal Microsoft accounts"
   - Redirect URI: Select "Public client/native (mobile & desktop)" and enter `writr://oauth2redirect`
5. Click "Register"

### Step 2: Configure API Permissions

1. In your app, go to "API permissions"
2. Click "Add a permission"
3. Select "Microsoft Graph"
4. Select "Delegated permissions"
5. Add these permissions:
   - `Files.ReadWrite`
   - `offline_access`
6. Click "Add permissions"

### Step 3: Get Your Client ID

1. Go to "Overview"
2. Copy the "Application (client) ID"

### Step 4: Update the Code

Open `lib/services/onedrive_provider.dart` and replace:

```dart
static const String _clientId = 'YOUR_MICROSOFT_CLIENT_ID';
```

with:

```dart
static const String _clientId = 'your_actual_client_id_here';
```

### Step 5: Configure Android Manifest

Add to `android/app/src/main/AndroidManifest.xml` inside the `<activity>` tag (if not already added for Dropbox):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="writr" android:host="oauth2redirect" />
</intent-filter>
```

---

## Testing Your Setup

### Test Google Drive

1. Build and run the app
2. Tap "Open Project"
3. Select "Google Drive"
4. Sign in with your Google account
5. Grant permissions
6. You should see your Drive files

### Test Dropbox

1. Tap "Open Project"
2. Select "Dropbox"
3. You'll be redirected to Dropbox login
4. Authorize the app
5. You should see your Dropbox files

### Test OneDrive

1. Tap "Open Project"
2. Select "OneDrive"
3. Sign in with your Microsoft account
4. Grant permissions
5. You should see your OneDrive files

---

## Troubleshooting

### Google Drive: "Sign in failed"

- Verify your SHA-1 certificate fingerprint is correct
- Make sure you added yourself as a test user in the OAuth consent screen
- Check that the Google Drive API is enabled
- Ensure the package name matches

### Dropbox: "Invalid app key"

- Double-check you copied the app key correctly
- Verify the redirect URI is configured correctly
- Make sure you submitted the permission changes

### OneDrive: "AADSTS50011: The redirect URI specified in the request does not match"

- Verify the redirect URI in Azure Portal is exactly `writr://oauth2redirect`
- Check that the intent filter in AndroidManifest.xml matches
- Make sure the scheme is lowercase

### General OAuth Issues

- Clear app data and try again
- Check internet connection
- Verify the redirect URI is configured in both the cloud provider console AND AndroidManifest.xml
- Look for error messages in the debug console

---

## Security Notes

- **Never commit API keys to public repositories**
- Consider using environment variables or secure storage for production
- Rotate credentials if they are accidentally exposed
- Use separate credentials for debug and release builds
- Review app permissions regularly

---

## OAuth Flow Limitations

**Important:** The current OAuth implementation uses `url_launcher` which has limitations:

1. After being redirected to the browser for authentication, you need to manually extract the access token
2. For production use, consider using packages like:
   - `flutter_web_auth` - Handles OAuth redirect automatically
   - `flutter_appauth` - Full OAuth 2.0 and OpenID Connect client

These packages can automatically capture the OAuth callback and extract tokens.

---

## Alternative: Using flutter_web_auth

For a better OAuth experience, you can add `flutter_web_auth` to `pubspec.yaml`:

```yaml
dependencies:
  flutter_web_auth: ^0.5.0
```

Then update the sign-in methods in each provider to use:

```dart
import 'package:flutter_web_auth/flutter_web_auth.dart';

final result = await FlutterWebAuth.authenticate(
  url: authUrl.toString(),
  callbackUrlScheme: 'writr',
);

// Extract token from result
final token = Uri.parse(result).fragment;
```

This will automatically handle the OAuth redirect and token extraction.

---

## Need Help?

- Check the [GitHub Issues](https://github.com/rogue780/Writr/issues)
- Review provider documentation:
  - [Google Drive API](https://developers.google.com/drive)
  - [Dropbox API](https://www.dropbox.com/developers/documentation)
  - [Microsoft Graph](https://docs.microsoft.com/en-us/graph/)
