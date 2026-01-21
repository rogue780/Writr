import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/theme_service.dart';
import 'theme_selector.dart';

/// Settings modal dialog for configuring app preferences
class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Editor'),
                Tab(text: 'General'),
                Tab(text: 'Appearance'),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EditorSettingsTab(),
                  _GeneralSettingsTab(),
                  _AppearanceSettingsTab(),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Editor settings tab
class _EditorSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesService>(
      builder: (context, prefs, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Font'),
            const SizedBox(height: 8),
            _buildFontFamilyDropdown(context, prefs),
            const SizedBox(height: 16),
            _buildFontSizeSlider(context, prefs),
            const SizedBox(height: 16),
            _buildLineHeightSlider(context, prefs),
            const SizedBox(height: 24),
            _buildSectionHeader('Editing'),
            const SizedBox(height: 8),
            _buildSpellCheckToggle(context, prefs),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildFontFamilyDropdown(
      BuildContext context, PreferencesService prefs) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('Font Family'),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: prefs.editorFontFamily,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: PreferencesService.availableFonts.map((font) {
              return DropdownMenuItem(
                value: font,
                child: Text(
                  font,
                  style: TextStyle(
                    fontFamily: font == 'System Default' ? null : font,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                prefs.setEditorFontFamily(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, PreferencesService prefs) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('Font Size'),
        ),
        Expanded(
          child: Slider(
            value: prefs.editorFontSize,
            min: 10,
            max: 32,
            divisions: 22,
            label: '${prefs.editorFontSize.round()}px',
            onChanged: (value) {
              prefs.setEditorFontSize(value);
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${prefs.editorFontSize.round()}px',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider(
      BuildContext context, PreferencesService prefs) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('Line Height'),
        ),
        Expanded(
          child: Slider(
            value: prefs.editorLineHeight,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            label: prefs.editorLineHeight.toStringAsFixed(1),
            onChanged: (value) {
              prefs.setEditorLineHeight(value);
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            prefs.editorLineHeight.toStringAsFixed(1),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildSpellCheckToggle(
      BuildContext context, PreferencesService prefs) {
    return SwitchListTile(
      title: const Text('Spell Check'),
      subtitle: const Text('Highlight spelling errors while typing'),
      value: prefs.spellCheckEnabled,
      onChanged: (value) {
        prefs.setSpellCheckEnabled(value);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// General settings tab
class _GeneralSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesService>(
      builder: (context, prefs, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Auto-Save'),
            const SizedBox(height: 8),
            _buildAutoSaveToggle(context, prefs),
            if (prefs.autoSaveEnabled) ...[
              const SizedBox(height: 8),
              _buildAutoSaveIntervalSlider(context, prefs),
            ],
            const SizedBox(height: 24),
            _buildSectionHeader('Page View'),
            const SizedBox(height: 8),
            _buildPageViewToggle(context, prefs),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildAutoSaveToggle(BuildContext context, PreferencesService prefs) {
    return SwitchListTile(
      title: const Text('Auto-Save'),
      subtitle: const Text('Automatically save changes'),
      value: prefs.autoSaveEnabled,
      onChanged: (value) {
        prefs.setAutoSaveEnabled(value);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAutoSaveIntervalSlider(
      BuildContext context, PreferencesService prefs) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('Save Interval'),
        ),
        Expanded(
          child: Slider(
            value: prefs.autoSaveInterval.toDouble(),
            min: 10,
            max: 120,
            divisions: 11,
            label: '${prefs.autoSaveInterval}s',
            onChanged: (value) {
              prefs.setAutoSaveInterval(value.round());
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${prefs.autoSaveInterval}s',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPageViewToggle(BuildContext context, PreferencesService prefs) {
    return SwitchListTile(
      title: const Text('Default Page View'),
      subtitle: const Text('Open documents in page view mode by default'),
      value: prefs.pageViewMode,
      onChanged: (value) {
        prefs.setPageViewMode(value);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Appearance settings tab
class _AppearanceSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ThemeSelector(themeService: themeService);
      },
    );
  }
}
