import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationPolicy extends StatefulWidget {
  const OrientationPolicy({
    super.key,
    required this.child,
    this.landscapeLockMaxShortestSide = 500,
  });

  final Widget child;

  /// On Android/iOS, lock the app to landscape when the shortest side is
  /// smaller than this value (treating it as a medium/small phone).
  final double landscapeLockMaxShortestSide;

  @override
  State<OrientationPolicy> createState() => _OrientationPolicyState();
}

class _OrientationPolicyState extends State<OrientationPolicy> {
  bool _isLockedToLandscape = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyPolicy();
  }

  @override
  void didUpdateWidget(OrientationPolicy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.landscapeLockMaxShortestSide !=
        widget.landscapeLockMaxShortestSide) {
      _applyPolicy();
    }
  }

  void _applyPolicy() {
    if (kIsWeb) {
      return;
    }

    final platform = Theme.of(context).platform;
    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (!isMobilePlatform) {
      return;
    }

    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final shouldLock = shortestSide < widget.landscapeLockMaxShortestSide;
    _setLandscapeLock(shouldLock);
  }

  void _setLandscapeLock(bool lock) {
    if (_isLockedToLandscape == lock) {
      return;
    }

    _isLockedToLandscape = lock;
    if (lock) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  void dispose() {
    if (_isLockedToLandscape) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

