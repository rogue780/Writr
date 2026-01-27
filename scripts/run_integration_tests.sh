#!/bin/bash
# Shell script to run integration tests
# Usage: ./scripts/run_integration_tests.sh [platform]
# Platforms: linux, chrome, android, ios, macos

set -e

PLATFORM=${1:-"linux"}
TEST_FILE=${2:-"integration_test/app_test.dart"}

echo "========================================"
echo "  Writr Integration Tests Runner"
echo "========================================"
echo ""

# Ensure we're in the project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"
echo "Platform: $PLATFORM"
echo "Test file: $TEST_FILE"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Run tests
echo ""
echo "Running: flutter test $TEST_FILE -d $PLATFORM"
echo ""

flutter test "$TEST_FILE" -d "$PLATFORM"
TEST_RESULT=$?

# Summary
echo ""
echo "========================================"
if [ $TEST_RESULT -eq 0 ]; then
    echo "  Tests PASSED"
else
    echo "  Tests FAILED"
fi
echo "========================================"

exit $TEST_RESULT
