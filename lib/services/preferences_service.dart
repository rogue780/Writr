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
  static const String _editorFontFamilyKey = 'editor_font_family';
  static const String _editorFontSizeKey = 'editor_font_size';
  static const String _editorLineHeightKey = 'editor_line_height';
  static const String _autoSaveEnabledKey = 'auto_save_enabled';
  static const String _autoSaveIntervalKey = 'auto_save_interval';
  static const String _spellCheckEnabledKey = 'spell_check_enabled';
  static const String _themeModeKey = 'theme_mode';

  SharedPreferences? _prefs;

  // Cached values
  ToolbarStyle _toolbarStyle = ToolbarStyle.menuBar;
  bool _pageViewMode = false;
  double _binderWidth = 250;
  double _inspectorWidth = 300;

  // Editor settings
  String _editorFontFamily = 'System Default';
  double _editorFontSize = 16.0;
  double _editorLineHeight = 1.5;
  bool _autoSaveEnabled = true;
  int _autoSaveInterval = 30; // seconds
  bool _spellCheckEnabled = true;
  String _themeMode = 'system'; // 'light', 'dark', 'system'

  // Getters
  ToolbarStyle get toolbarStyle => _toolbarStyle;
  bool get pageViewMode => _pageViewMode;
  double get binderWidth => _binderWidth;
  double get inspectorWidth => _inspectorWidth;

  // Editor settings getters
  String get editorFontFamily => _editorFontFamily;
  double get editorFontSize => _editorFontSize;
  double get editorLineHeight => _editorLineHeight;
  bool get autoSaveEnabled => _autoSaveEnabled;
  int get autoSaveInterval => _autoSaveInterval;
  bool get spellCheckEnabled => _spellCheckEnabled;
  String get themeMode => _themeMode;

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

    // Load editor settings
    _editorFontFamily = _prefs!.getString(_editorFontFamilyKey) ?? 'System Default';
    _editorFontSize = _prefs!.getDouble(_editorFontSizeKey) ?? 16.0;
    _editorLineHeight = _prefs!.getDouble(_editorLineHeightKey) ?? 1.5;
    _autoSaveEnabled = _prefs!.getBool(_autoSaveEnabledKey) ?? true;
    _autoSaveInterval = _prefs!.getInt(_autoSaveIntervalKey) ?? 30;
    _spellCheckEnabled = _prefs!.getBool(_spellCheckEnabledKey) ?? true;
    _themeMode = _prefs!.getString(_themeModeKey) ?? 'system';

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

  /// Set editor font family
  Future<void> setEditorFontFamily(String fontFamily) async {
    _editorFontFamily = fontFamily;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setString(_editorFontFamilyKey, fontFamily);
  }

  /// Set editor font size
  Future<void> setEditorFontSize(double size) async {
    _editorFontSize = size;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_editorFontSizeKey, size);
  }

  /// Set editor line height
  Future<void> setEditorLineHeight(double height) async {
    _editorLineHeight = height;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_editorLineHeightKey, height);
  }

  /// Set auto-save enabled
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled = enabled;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setBool(_autoSaveEnabledKey, enabled);
  }

  /// Set auto-save interval in seconds
  Future<void> setAutoSaveInterval(int seconds) async {
    _autoSaveInterval = seconds;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setInt(_autoSaveIntervalKey, seconds);
  }

  /// Set spell check enabled
  Future<void> setSpellCheckEnabled(bool enabled) async {
    _spellCheckEnabled = enabled;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setBool(_spellCheckEnabledKey, enabled);
  }

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await _ensurePrefs();
    await prefs.setString(_themeModeKey, mode);
  }

  /// Get available font families for the editor
  static List<String> get availableFonts => [
    'System Default',
    'Roboto',
    'Open Sans',
    'Lato',
    'Source Sans Pro',
    'Merriweather',
    'Lora',
    'Playfair Display',
    'Georgia',
    'Times New Roman',
    'Courier New',
    'Consolas',
    'Fira Code',
  ];
}
