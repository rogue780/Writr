#!/bin/bash
# run-with-secrets.sh
# Runs Flutter with cloud API keys from env.json
#
# Usage:
#   ./scripts/run-with-secrets.sh              # Run debug
#   ./scripts/run-with-secrets.sh --build      # Build release APK
#   ./scripts/run-with-secrets.sh --build-debug # Build debug APK
#   ./scripts/run-with-secrets.sh -d <device>  # Run on specific device

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/env.json"

# Parse arguments
BUILD_RELEASE=false
BUILD_DEBUG=false
DEVICE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD_RELEASE=true
            shift
            ;;
        --build-debug)
            BUILD_DEBUG=true
            shift
            ;;
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check env.json exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "\033[31mERROR: env.json not found!\033[0m"
    echo ""
    echo -e "\033[33mCreate env.json from the example:\033[0m"
    echo -e "\033[36m  cp env.json.example env.json\033[0m"
    echo ""
    echo -e "\033[33mThen fill in your API keys.\033[0m"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "\033[31mERROR: jq is required but not installed.\033[0m"
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Load keys from JSON
DROPBOX_APP_KEY=$(jq -r '.DROPBOX_APP_KEY // ""' "$ENV_FILE")
ONEDRIVE_CLIENT_ID=$(jq -r '.ONEDRIVE_CLIENT_ID // ""' "$ENV_FILE")

# Validate keys
if [ -z "$DROPBOX_APP_KEY" ] || [ "$DROPBOX_APP_KEY" == "your_dropbox_app_key_here" ]; then
    echo -e "\033[33mWARNING: DROPBOX_APP_KEY not configured in env.json\033[0m"
    DROPBOX_APP_KEY=""
fi

if [ -z "$ONEDRIVE_CLIENT_ID" ] || [ "$ONEDRIVE_CLIENT_ID" == "your_onedrive_client_id_here" ]; then
    echo -e "\033[33mWARNING: ONEDRIVE_CLIENT_ID not configured in env.json\033[0m"
    ONEDRIVE_CLIENT_ID=""
fi

# Build dart-define arguments
DART_DEFINES=""
if [ -n "$DROPBOX_APP_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=DROPBOX_APP_KEY=$DROPBOX_APP_KEY"
fi
if [ -n "$ONEDRIVE_CLIENT_ID" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=ONEDRIVE_CLIENT_ID=$ONEDRIVE_CLIENT_ID"
fi

cd "$PROJECT_DIR"

if [ "$BUILD_RELEASE" = true ]; then
    echo -e "\033[32mBuilding release APK with cloud credentials...\033[0m"
    CMD="flutter build apk --release $DART_DEFINES"
    echo -e "\033[36m> $CMD\033[0m"
    eval $CMD

    echo ""
    echo -e "\033[32mRelease APK built at:\033[0m"
    echo -e "\033[36m  build/app/outputs/flutter-apk/app-release.apk\033[0m"

elif [ "$BUILD_DEBUG" = true ]; then
    echo -e "\033[32mBuilding debug APK with cloud credentials...\033[0m"
    CMD="flutter build apk --debug $DART_DEFINES"
    echo -e "\033[36m> $CMD\033[0m"
    eval $CMD

    echo ""
    echo -e "\033[32mDebug APK built at:\033[0m"
    echo -e "\033[36m  build/app/outputs/flutter-apk/app-debug.apk\033[0m"

else
    echo -e "\033[32mRunning Flutter with cloud credentials...\033[0m"
    DEVICE_ARG=""
    if [ -n "$DEVICE" ]; then
        DEVICE_ARG="-d $DEVICE"
    fi
    CMD="flutter run $DEVICE_ARG $DART_DEFINES"
    echo -e "\033[36m> $CMD\033[0m"
    eval $CMD
fi
