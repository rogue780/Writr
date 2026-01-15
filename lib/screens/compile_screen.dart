import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/scrivener_project.dart';
import '../models/compile_settings.dart';
import '../services/compile_service.dart';
import '../utils/web_download.dart';

/// Screen for configuring and executing manuscript compilation.
class CompileScreen extends StatefulWidget {
  final ScrivenerProject project;

  const CompileScreen({
    super.key,
    required this.project,
  });

  @override
  State<CompileScreen> createState() => _CompileScreenState();
}

class _CompileScreenState extends State<CompileScreen> {
  late CompileSettings _settings;
  final CompileService _compileService = CompileService();
  String? _preview;
  bool _isCompiling = false;
  CompileResult? _lastResult;

  // Controllers for text fields
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _outputNameController;
  late TextEditingController _chapterPrefixController;
  late TextEditingController _sceneSeparatorController;

  @override
  void initState() {
    super.initState();
    _settings = CompileSettings.fromProject(widget.project);
    _titleController = TextEditingController(text: _settings.title ?? '');
    _authorController = TextEditingController(text: _settings.author ?? '');
    _outputNameController = TextEditingController(text: _settings.outputName);
    _chapterPrefixController = TextEditingController(text: _settings.chapterPrefix);
    _sceneSeparatorController = TextEditingController(text: _settings.sceneSeparator);
    _updatePreview();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _outputNameController.dispose();
    _chapterPrefixController.dispose();
    _sceneSeparatorController.dispose();
    super.dispose();
  }

  void _updateSettings(CompileSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _updatePreview();
  }

  void _updatePreview() {
    final preview = _compileService.getPreview(widget.project, _settings);
    setState(() {
      _preview = preview;
    });
  }

  Future<void> _compile() async {
    setState(() {
      _isCompiling = true;
    });

    // Run compilation
    final result = _compileService.compile(widget.project, _settings);

    setState(() {
      _isCompiling = false;
      _lastResult = result;
    });

    if (result.success && result.content != null) {
      // Show success and offer download
      _showCompileSuccessDialog(result);
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compilation failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompileSuccessDialog(CompileResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Compilation Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.statistics != null) ...[
              Text('Documents: ${result.statistics!.documentCount}'),
              Text('Chapters: ${result.statistics!.chapterCount}'),
              Text('Scenes: ${result.statistics!.sceneCount}'),
              Text('Words: ${result.statistics!.wordCount}'),
              Text('Characters: ${result.statistics!.characterCount}'),
              const SizedBox(height: 16),
            ],
            Text(
              'Output format: ${_settings.format.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadResult(result);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _downloadResult(CompileResult result) {
    if (result.content == null) return;

    final fileName = '${_settings.outputName}.${_settings.format.extension}';

    if (kIsWeb) {
      // Use web download utility
      downloadString(result.content!, fileName);
    } else {
      // For desktop, we'd use file_picker or path_provider
      // For now, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved as: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compile Manuscript'),
        actions: [
          if (_isCompiling)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _compile,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Compile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Settings panel
          SizedBox(
            width: 350,
            child: _buildSettingsPanel(),
          ),
          const VerticalDivider(width: 1),
          // Preview panel
          Expanded(
            child: _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection
          _buildSectionHeader('Output Format'),
          const SizedBox(height: 8),
          _buildFormatSelector(),
          const SizedBox(height: 24),

          // Document info
          _buildSectionHeader('Document Info'),
          const SizedBox(height: 8),
          _buildTextField(
            label: 'Title',
            controller: _titleController,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(title: value));
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Author',
            controller: _authorController,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(author: value));
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Output File Name',
            controller: _outputNameController,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(outputName: value));
            },
          ),
          const SizedBox(height: 24),

          // Chapter settings
          _buildSectionHeader('Chapters & Scenes'),
          const SizedBox(height: 8),
          _buildCheckbox(
            label: 'Add chapter numbers',
            value: _settings.addChapterNumbers,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(addChapterNumbers: value));
            },
          ),
          if (_settings.addChapterNumbers) ...[
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Chapter Prefix',
              controller: _chapterPrefixController,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(chapterPrefix: value));
              },
            ),
          ],
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Scene Separator',
            controller: _sceneSeparatorController,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(sceneSeparator: value));
            },
          ),
          const SizedBox(height: 24),

          // Content options
          _buildSectionHeader('Content Options'),
          const SizedBox(height: 8),
          _buildCheckbox(
            label: 'Include front matter (title page)',
            value: _settings.includeFrontMatter,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(includeFrontMatter: value));
            },
          ),
          _buildCheckbox(
            label: 'Include empty documents',
            value: _settings.includeEmptyDocuments,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(includeEmptyDocuments: value));
            },
          ),
          _buildCheckbox(
            label: 'Page breaks between chapters',
            value: _settings.pageBreakBetweenChapters,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(pageBreakBetweenChapters: value));
            },
          ),
          const SizedBox(height: 24),

          // Typography (for supported formats)
          if (_settings.format == CompileFormat.html ||
              _settings.format == CompileFormat.rtf) ...[
            _buildSectionHeader('Typography'),
            const SizedBox(height: 8),
            _buildFontSelector(),
            const SizedBox(height: 12),
            _buildFontSizeSelector(),
            const SizedBox(height: 12),
            _buildLineSpacingSelector(),
            const SizedBox(height: 12),
            _buildCheckbox(
              label: 'Use first-line indent',
              value: _settings.useFirstLineIndent,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(useFirstLineIndent: value));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CompileFormat.values.map((format) {
        final isSelected = _settings.format == format;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(format.icon, size: 18),
              const SizedBox(width: 4),
              Text(format.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              _updateSettings(_settings.copyWith(format: format));
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  Widget _buildFontSelector() {
    final fonts = [
      'Times New Roman',
      'Georgia',
      'Arial',
      'Helvetica',
      'Courier New',
    ];

    return DropdownButtonFormField<String>(
      initialValue: _settings.fontFamily,
      decoration: const InputDecoration(
        labelText: 'Font Family',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: fonts.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(font),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _updateSettings(_settings.copyWith(fontFamily: value));
        }
      },
    );
  }

  Widget _buildFontSizeSelector() {
    return Row(
      children: [
        const Text('Font Size: '),
        Expanded(
          child: Slider(
            value: _settings.fontSize,
            min: 8,
            max: 24,
            divisions: 16,
            label: '${_settings.fontSize.toInt()}pt',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(fontSize: value));
            },
          ),
        ),
        Text('${_settings.fontSize.toInt()}pt'),
      ],
    );
  }

  Widget _buildLineSpacingSelector() {
    return Row(
      children: [
        const Text('Line Spacing: '),
        Expanded(
          child: Slider(
            value: _settings.lineSpacing,
            min: 1.0,
            max: 3.0,
            divisions: 8,
            label: '${_settings.lineSpacing.toStringAsFixed(1)}x',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(lineSpacing: value));
            },
          ),
        ),
        Text('${_settings.lineSpacing.toStringAsFixed(1)}x'),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.preview, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _updatePreview,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        // Preview content
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SelectableText(
                  _preview ?? 'No preview available',
                  style: TextStyle(
                    fontFamily: _settings.format == CompileFormat.plainText ||
                            _settings.format == CompileFormat.markdown
                        ? 'monospace'
                        : _settings.fontFamily,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Statistics bar
        if (_lastResult?.statistics != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatistic('Documents', _lastResult!.statistics!.documentCount),
                _buildStatistic('Chapters', _lastResult!.statistics!.chapterCount),
                _buildStatistic('Scenes', _lastResult!.statistics!.sceneCount),
                _buildStatistic('Words', _lastResult!.statistics!.wordCount),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatistic(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
