import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Toolbar style options
enum ToolbarStyle {
  menuBar,    // Traditional File/Edit/View menus
  simplified, // Modern grouped dropdowns
}

/// Service for managing user preferences
class PreferencesService extends ChangeNotifier {
  static const String _toolbarStyleKey = 'toolbar_style';
  static const String _pageViewModeKey = 'page_view_mode';
  static const String _binderWidthKey = 'binder_width';
  static const String _inspectorWidthKey = 'inspector_width';

  SharedPreferences? _prefs;

  // Cached values
  ToolbarStyle _toolbarStyle = ToolbarStyle.menuBar;
  bool _pageViewMode = false;
  double _binderWidth = 250;
  double _inspectorWidth = 300;

  // Getters
  ToolbarStyle get toolbarStyle => _toolbarStyle;
  bool get pageViewMode => _pageViewMode;
  double get binderWidth => _binderWidth;
  double get inspectorWidth => _inspectorWidth;

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    final existing = _prefs;
    if (existing != null) {
      return existing;
    }

    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  void _loadPreferences() {
    if (_prefs == null) return;

    // Load toolbar style
    final styleIndex = _prefs!.getInt(_toolbarStyleKey);
    if (styleIndex != null && styleIndex < ToolbarStyle.values.length) {
      _toolbarStyle = ToolbarStyle.values[styleIndex];
    }

    // Load page view mode
    _pageViewMode = _prefs!.getBool(_pageViewModeKey) ?? false;

    // Load panel widths
    _binderWidth = _prefs!.getDouble(_binderWidthKey) ?? 250;
    _inspectorWidth = _prefs!.getDouble(_inspectorWidthKey) ?? 300;

    notifyListeners();
  }

  /// Set the toolbar style
  Future<void> setToolbarStyle(ToolbarStyle style) async {
    _toolbarStyle = style;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setInt(_toolbarStyleKey, style.index);
  }

  /// Set page view mode
  Future<void> setPageViewMode(bool enabled) async {
    _pageViewMode = enabled;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setBool(_pageViewModeKey, enabled);
  }

  /// Set binder width
  Future<void> setBinderWidth(double width, {bool persist = true}) async {
    _binderWidth = width;
    if (!persist) {
      return;
    }
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_binderWidthKey, width);
  }

  /// Set inspector width
  Future<void> setInspectorWidth(double width, {bool persist = true}) async {
    _inspectorWidth = width;
    if (!persist) {
      return;
    }
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_inspectorWidthKey, width);
  }

  /// Toggle between toolbar styles
  Future<void> toggleToolbarStyle() async {
    final newStyle = _toolbarStyle == ToolbarStyle.menuBar
        ? ToolbarStyle.simplified
        : ToolbarStyle.menuBar;
    await setToolbarStyle(newStyle);
  }
}
