import 'dart:convert';
import 'package:flutter/material.dart';

/// All customizable colors in a theme
class AppThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainerHighest;
  final Color surfaceContainerHigh;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerLowest;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  const AppThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainerHighest,
    required this.surfaceContainerHigh,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  AppThemeColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceContainerHighest,
    Color? surfaceContainerHigh,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerLowest,
    Color? outline,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
    );
  }

  /// Update a single color by property name
  AppThemeColors copyWithProperty(String property, Color color) {
    switch (property) {
      case 'primary':
        return copyWith(primary: color);
      case 'onPrimary':
        return copyWith(onPrimary: color);
      case 'primaryContainer':
        return copyWith(primaryContainer: color);
      case 'onPrimaryContainer':
        return copyWith(onPrimaryContainer: color);
      case 'secondary':
        return copyWith(secondary: color);
      case 'onSecondary':
        return copyWith(onSecondary: color);
      case 'secondaryContainer':
        return copyWith(secondaryContainer: color);
      case 'onSecondaryContainer':
        return copyWith(onSecondaryContainer: color);
      case 'tertiary':
        return copyWith(tertiary: color);
      case 'onTertiary':
        return copyWith(onTertiary: color);
      case 'tertiaryContainer':
        return copyWith(tertiaryContainer: color);
      case 'onTertiaryContainer':
        return copyWith(onTertiaryContainer: color);
      case 'error':
        return copyWith(error: color);
      case 'onError':
        return copyWith(onError: color);
      case 'errorContainer':
        return copyWith(errorContainer: color);
      case 'onErrorContainer':
        return copyWith(onErrorContainer: color);
      case 'surface':
        return copyWith(surface: color);
      case 'onSurface':
        return copyWith(onSurface: color);
      case 'surfaceContainerHighest':
        return copyWith(surfaceContainerHighest: color);
      case 'surfaceContainerHigh':
        return copyWith(surfaceContainerHigh: color);
      case 'surfaceContainer':
        return copyWith(surfaceContainer: color);
      case 'surfaceContainerLow':
        return copyWith(surfaceContainerLow: color);
      case 'surfaceContainerLowest':
        return copyWith(surfaceContainerLowest: color);
      case 'outline':
        return copyWith(outline: color);
      case 'outlineVariant':
        return copyWith(outlineVariant: color);
      case 'shadow':
        return copyWith(shadow: color);
      case 'scrim':
        return copyWith(scrim: color);
      case 'inverseSurface':
        return copyWith(inverseSurface: color);
      case 'onInverseSurface':
        return copyWith(onInverseSurface: color);
      case 'inversePrimary':
        return copyWith(inversePrimary: color);
      default:
        return this;
    }
  }

  /// Get color by property name
  Color? getByProperty(String property) {
    switch (property) {
      case 'primary':
        return primary;
      case 'onPrimary':
        return onPrimary;
      case 'primaryContainer':
        return primaryContainer;
      case 'onPrimaryContainer':
        return onPrimaryContainer;
      case 'secondary':
        return secondary;
      case 'onSecondary':
        return onSecondary;
      case 'secondaryContainer':
        return secondaryContainer;
      case 'onSecondaryContainer':
        return onSecondaryContainer;
      case 'tertiary':
        return tertiary;
      case 'onTertiary':
        return onTertiary;
      case 'tertiaryContainer':
        return tertiaryContainer;
      case 'onTertiaryContainer':
        return onTertiaryContainer;
      case 'error':
        return error;
      case 'onError':
        return onError;
      case 'errorContainer':
        return errorContainer;
      case 'onErrorContainer':
        return onErrorContainer;
      case 'surface':
        return surface;
      case 'onSurface':
        return onSurface;
      case 'surfaceContainerHighest':
        return surfaceContainerHighest;
      case 'surfaceContainerHigh':
        return surfaceContainerHigh;
      case 'surfaceContainer':
        return surfaceContainer;
      case 'surfaceContainerLow':
        return surfaceContainerLow;
      case 'surfaceContainerLowest':
        return surfaceContainerLowest;
      case 'outline':
        return outline;
      case 'outlineVariant':
        return outlineVariant;
      case 'shadow':
        return shadow;
      case 'scrim':
        return scrim;
      case 'inverseSurface':
        return inverseSurface;
      case 'onInverseSurface':
        return onInverseSurface;
      case 'inversePrimary':
        return inversePrimary;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'primary': _colorToHex(primary),
        'onPrimary': _colorToHex(onPrimary),
        'primaryContainer': _colorToHex(primaryContainer),
        'onPrimaryContainer': _colorToHex(onPrimaryContainer),
        'secondary': _colorToHex(secondary),
        'onSecondary': _colorToHex(onSecondary),
        'secondaryContainer': _colorToHex(secondaryContainer),
        'onSecondaryContainer': _colorToHex(onSecondaryContainer),
        'tertiary': _colorToHex(tertiary),
        'onTertiary': _colorToHex(onTertiary),
        'tertiaryContainer': _colorToHex(tertiaryContainer),
        'onTertiaryContainer': _colorToHex(onTertiaryContainer),
        'error': _colorToHex(error),
        'onError': _colorToHex(onError),
        'errorContainer': _colorToHex(errorContainer),
        'onErrorContainer': _colorToHex(onErrorContainer),
        'surface': _colorToHex(surface),
        'onSurface': _colorToHex(onSurface),
        'surfaceContainerHighest': _colorToHex(surfaceContainerHighest),
        'surfaceContainerHigh': _colorToHex(surfaceContainerHigh),
        'surfaceContainer': _colorToHex(surfaceContainer),
        'surfaceContainerLow': _colorToHex(surfaceContainerLow),
        'surfaceContainerLowest': _colorToHex(surfaceContainerLowest),
        'outline': _colorToHex(outline),
        'outlineVariant': _colorToHex(outlineVariant),
        'shadow': _colorToHex(shadow),
        'scrim': _colorToHex(scrim),
        'inverseSurface': _colorToHex(inverseSurface),
        'onInverseSurface': _colorToHex(onInverseSurface),
        'inversePrimary': _colorToHex(inversePrimary),
      };

  factory AppThemeColors.fromJson(Map<String, dynamic> json) => AppThemeColors(
        primary: _hexToColor(json['primary']),
        onPrimary: _hexToColor(json['onPrimary']),
        primaryContainer: _hexToColor(json['primaryContainer']),
        onPrimaryContainer: _hexToColor(json['onPrimaryContainer']),
        secondary: _hexToColor(json['secondary']),
        onSecondary: _hexToColor(json['onSecondary']),
        secondaryContainer: _hexToColor(json['secondaryContainer']),
        onSecondaryContainer: _hexToColor(json['onSecondaryContainer']),
        tertiary: _hexToColor(json['tertiary']),
        onTertiary: _hexToColor(json['onTertiary']),
        tertiaryContainer: _hexToColor(json['tertiaryContainer']),
        onTertiaryContainer: _hexToColor(json['onTertiaryContainer']),
        error: _hexToColor(json['error']),
        onError: _hexToColor(json['onError']),
        errorContainer: _hexToColor(json['errorContainer']),
        onErrorContainer: _hexToColor(json['onErrorContainer']),
        surface: _hexToColor(json['surface']),
        onSurface: _hexToColor(json['onSurface']),
        surfaceContainerHighest: _hexToColor(json['surfaceContainerHighest']),
        surfaceContainerHigh: _hexToColor(json['surfaceContainerHigh']),
        surfaceContainer: _hexToColor(json['surfaceContainer']),
        surfaceContainerLow: _hexToColor(json['surfaceContainerLow']),
        surfaceContainerLowest: _hexToColor(json['surfaceContainerLowest']),
        outline: _hexToColor(json['outline']),
        outlineVariant: _hexToColor(json['outlineVariant']),
        shadow: _hexToColor(json['shadow']),
        scrim: _hexToColor(json['scrim']),
        inverseSurface: _hexToColor(json['inverseSurface']),
        onInverseSurface: _hexToColor(json['onInverseSurface']),
        inversePrimary: _hexToColor(json['inversePrimary']),
      );

  static String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Generate ColorScheme from these colors
  ColorScheme toColorScheme(Brightness brightness) => ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: shadow,
        scrim: scrim,
        inverseSurface: inverseSurface,
        onInverseSurface: onInverseSurface,
        inversePrimary: inversePrimary,
      );
}

/// Represents a complete app theme with metadata
class AppTheme {
  final String id;
  final String name;
  final String? description;
  final bool isCustom;
  final String? basedOnPresetId;
  final Brightness brightness;
  final AppThemeColors colors;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const AppTheme({
    required this.id,
    required this.name,
    this.description,
    this.isCustom = false,
    this.basedOnPresetId,
    required this.brightness,
    required this.colors,
    this.createdAt,
    this.modifiedAt,
  });

  AppTheme copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCustom,
    String? basedOnPresetId,
    Brightness? brightness,
    AppThemeColors? colors,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      basedOnPresetId: basedOnPresetId ?? this.basedOnPresetId,
      brightness: brightness ?? this.brightness,
      colors: colors ?? this.colors,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Create a custom copy of this theme
  AppTheme copyAsCustom({required String newId, required String newName}) {
    return AppTheme(
      id: newId,
      name: newName,
      isCustom: true,
      basedOnPresetId: isCustom ? basedOnPresetId : id,
      brightness: brightness,
      colors: colors,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Generate ThemeData for MaterialApp
  ThemeData toThemeData() {
    final colorScheme = colors.toColorScheme(brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isCustom': isCustom,
        'basedOnPresetId': basedOnPresetId,
        'brightness': brightness.name,
        'colors': colors.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'modifiedAt': modifiedAt?.toIso8601String(),
      };

  factory AppTheme.fromJson(Map<String, dynamic> json) => AppTheme(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        isCustom: json['isCustom'] ?? true,
        basedOnPresetId: json['basedOnPresetId'],
        brightness: Brightness.values.firstWhere(
          (b) => b.name == json['brightness'],
          orElse: () => Brightness.light,
        ),
        colors: AppThemeColors.fromJson(json['colors']),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        modifiedAt: json['modifiedAt'] != null
            ? DateTime.parse(json['modifiedAt'])
            : null,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AppTheme.fromJsonString(String jsonString) =>
      AppTheme.fromJson(jsonDecode(jsonString));
}

/// Built-in preset themes
class PresetThemes {
  static const String lightId = 'preset_light';
  static const String darkId = 'preset_dark';
  static const String blueId = 'preset_blue';
  static const String sepiaId = 'preset_sepia';
  static const String hotdogStandId = 'preset_hotdog_stand';
  static const String nordId = 'preset_nord';
  static const String solarizedId = 'preset_solarized';

  // Material 3 Light Theme
  static const AppTheme light = AppTheme(
    id: lightId,
    name: 'Light',
    description: 'Clean Material 3 light theme',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF6750A4),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFEADDFF),
      onPrimaryContainer: Color(0xFF21005D),
      secondary: Color(0xFF625B71),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE8DEF8),
      onSecondaryContainer: Color(0xFF1D192B),
      tertiary: Color(0xFF7D5260),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFD8E4),
      onTertiaryContainer: Color(0xFF31111D),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: Color(0xFFFEF7FF),
      onSurface: Color(0xFF1D1B20),
      surfaceContainerHighest: Color(0xFFE6E0E9),
      surfaceContainerHigh: Color(0xFFECE6F0),
      surfaceContainer: Color(0xFFF3EDF7),
      surfaceContainerLow: Color(0xFFF7F2FA),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF322F35),
      onInverseSurface: Color(0xFFF5EFF7),
      inversePrimary: Color(0xFFD0BCFF),
    ),
  );

  // Material 3 Dark Theme
  static const AppTheme dark = AppTheme(
    id: darkId,
    name: 'Dark',
    description: 'Material 3 dark theme',
    brightness: Brightness.dark,
    colors: AppThemeColors(
      primary: Color(0xFFD0BCFF),
      onPrimary: Color(0xFF381E72),
      primaryContainer: Color(0xFF4F378B),
      onPrimaryContainer: Color(0xFFEADDFF),
      secondary: Color(0xFFCCC2DC),
      onSecondary: Color(0xFF332D41),
      secondaryContainer: Color(0xFF4A4458),
      onSecondaryContainer: Color(0xFFE8DEF8),
      tertiary: Color(0xFFEFB8C8),
      onTertiary: Color(0xFF492532),
      tertiaryContainer: Color(0xFF633B48),
      onTertiaryContainer: Color(0xFFFFD8E4),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      surface: Color(0xFF141218),
      onSurface: Color(0xFFE6E0E9),
      surfaceContainerHighest: Color(0xFF36343B),
      surfaceContainerHigh: Color(0xFF2B2930),
      surfaceContainer: Color(0xFF211F26),
      surfaceContainerLow: Color(0xFF1D1B20),
      surfaceContainerLowest: Color(0xFF0F0D13),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E0E9),
      onInverseSurface: Color(0xFF322F35),
      inversePrimary: Color(0xFF6750A4),
    ),
  );

  // Ocean Blue Theme
  static const AppTheme blue = AppTheme(
    id: blueId,
    name: 'Ocean Blue',
    description: 'Calming blue color scheme',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF0061A4),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD1E4FF),
      onPrimaryContainer: Color(0xFF001D36),
      secondary: Color(0xFF535F70),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFD7E3F7),
      onSecondaryContainer: Color(0xFF101C2B),
      tertiary: Color(0xFF6B5778),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFF2DAFF),
      onTertiaryContainer: Color(0xFF251431),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFDFCFF),
      onSurface: Color(0xFF1A1C1E),
      surfaceContainerHighest: Color(0xFFDEE3EB),
      surfaceContainerHigh: Color(0xFFE4E9F0),
      surfaceContainer: Color(0xFFEAEEF6),
      surfaceContainerLow: Color(0xFFF0F4FB),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      outline: Color(0xFF73777F),
      outlineVariant: Color(0xFFC3C7CF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFF9ECAFF),
    ),
  );

  // Sepia/Brown Theme (reading-friendly warm tones)
  static const AppTheme sepia = AppTheme(
    id: sepiaId,
    name: 'Sepia',
    description: 'Warm brown tones for comfortable reading',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF8B5A2B),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFDCC2),
      onPrimaryContainer: Color(0xFF2E1500),
      secondary: Color(0xFF765848),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDCC8),
      onSecondaryContainer: Color(0xFF2B160A),
      tertiary: Color(0xFF636032),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFEAE5AB),
      onTertiaryContainer: Color(0xFF1E1C00),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFFF8F5),
      onSurface: Color(0xFF211A14),
      surfaceContainerHighest: Color(0xFFEDE0D4),
      surfaceContainerHigh: Color(0xFFF3E5D9),
      surfaceContainer: Color(0xFFF9EBDE),
      surfaceContainerLow: Color(0xFFFDF0E5),
      surfaceContainerLowest: Color(0xFFFFFBFF),
      outline: Color(0xFF857369),
      outlineVariant: Color(0xFFD7C2B4),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF372F28),
      onInverseSurface: Color(0xFFFDEEE3),
      inversePrimary: Color(0xFFFFB77C),
    ),
  );

  // Hotdog Stand Theme (Windows 3.1 classic)
  static const AppTheme hotdogStand = AppTheme(
    id: hotdogStandId,
    name: 'Hotdog Stand',
    description: 'Windows 3.1 classic: red, yellow, and black',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFFCC0000),
      onPrimary: Color(0xFFFFFF00),
      primaryContainer: Color(0xFFFFFF00),
      onPrimaryContainer: Color(0xFF000000),
      secondary: Color(0xFFFFFF00),
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFFCC0000),
      onSecondaryContainer: Color(0xFFFFFF00),
      tertiary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFF00),
      tertiaryContainer: Color(0xFFFFFF00),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFF000000),
      onError: Color(0xFFFFFF00),
      errorContainer: Color(0xFFFFFF00),
      onErrorContainer: Color(0xFF000000),
      surface: Color(0xFFCC0000),
      onSurface: Color(0xFFFFFF00),
      surfaceContainerHighest: Color(0xFFAA0000),
      surfaceContainerHigh: Color(0xFFBB0000),
      surfaceContainer: Color(0xFFCC0000),
      surfaceContainerLow: Color(0xFFDD0000),
      surfaceContainerLowest: Color(0xFFEE0000),
      outline: Color(0xFF000000),
      outlineVariant: Color(0xFFFFFF00),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFFFFF00),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF000000),
    ),
  );

  // Nord Theme (Arctic blue-gray dark theme)
  static const AppTheme nord = AppTheme(
    id: nordId,
    name: 'Nord',
    description: 'Arctic, north-bluish color palette',
    brightness: Brightness.dark,
    colors: AppThemeColors(
      primary: Color(0xFF88C0D0),
      onPrimary: Color(0xFF2E3440),
      primaryContainer: Color(0xFF5E81AC),
      onPrimaryContainer: Color(0xFFECEFF4),
      secondary: Color(0xFF81A1C1),
      onSecondary: Color(0xFF2E3440),
      secondaryContainer: Color(0xFF4C566A),
      onSecondaryContainer: Color(0xFFECEFF4),
      tertiary: Color(0xFFA3BE8C),
      onTertiary: Color(0xFF2E3440),
      tertiaryContainer: Color(0xFF4C566A),
      onTertiaryContainer: Color(0xFFECEFF4),
      error: Color(0xFFBF616A),
      onError: Color(0xFF2E3440),
      errorContainer: Color(0xFF4C566A),
      onErrorContainer: Color(0xFFBF616A),
      surface: Color(0xFF2E3440),
      onSurface: Color(0xFFECEFF4),
      surfaceContainerHighest: Color(0xFF4C566A),
      surfaceContainerHigh: Color(0xFF434C5E),
      surfaceContainer: Color(0xFF3B4252),
      surfaceContainerLow: Color(0xFF2E3440),
      surfaceContainerLowest: Color(0xFF242933),
      outline: Color(0xFF81A1C1),
      outlineVariant: Color(0xFF4C566A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFECEFF4),
      onInverseSurface: Color(0xFF2E3440),
      inversePrimary: Color(0xFF5E81AC),
    ),
  );

  // Solarized Light Theme
  static const AppTheme solarized = AppTheme(
    id: solarizedId,
    name: 'Solarized Light',
    description: 'Precision colors for readability',
    brightness: Brightness.light,
    colors: AppThemeColors(
      primary: Color(0xFF268BD2),
      onPrimary: Color(0xFFFDF6E3),
      primaryContainer: Color(0xFFEEE8D5),
      onPrimaryContainer: Color(0xFF073642),
      secondary: Color(0xFF2AA198),
      onSecondary: Color(0xFFFDF6E3),
      secondaryContainer: Color(0xFFEEE8D5),
      onSecondaryContainer: Color(0xFF073642),
      tertiary: Color(0xFF859900),
      onTertiary: Color(0xFFFDF6E3),
      tertiaryContainer: Color(0xFFEEE8D5),
      onTertiaryContainer: Color(0xFF073642),
      error: Color(0xFFDC322F),
      onError: Color(0xFFFDF6E3),
      errorContainer: Color(0xFFEEE8D5),
      onErrorContainer: Color(0xFFDC322F),
      surface: Color(0xFFFDF6E3),
      onSurface: Color(0xFF657B83),
      surfaceContainerHighest: Color(0xFFEEE8D5),
      surfaceContainerHigh: Color(0xFFF0EAD6),
      surfaceContainer: Color(0xFFF5EFDC),
      surfaceContainerLow: Color(0xFFFAF4E7),
      surfaceContainerLowest: Color(0xFFFDF6E3),
      outline: Color(0xFF93A1A1),
      outlineVariant: Color(0xFFEEE8D5),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF073642),
      onInverseSurface: Color(0xFFFDF6E3),
      inversePrimary: Color(0xFF268BD2),
    ),
  );

  /// All preset themes
  static List<AppTheme> get all =>
      [light, dark, blue, sepia, hotdogStand, nord, solarized];

  /// Get a preset theme by ID
  static AppTheme? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
