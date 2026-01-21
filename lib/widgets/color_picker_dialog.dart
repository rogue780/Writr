import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dialog for selecting colors with hex input, RGB sliders, and preset colors
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String? title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title,
  });

  /// Show the color picker dialog and return the selected color
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String? title,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;

  // Material color presets
  static const List<Color> _presetColors = [
    // Row 1: Reds to Purples
    Color(0xFFD32F2F), // Red
    Color(0xFFC2185B), // Pink
    Color(0xFF7B1FA2), // Purple
    Color(0xFF512DA8), // Deep Purple
    Color(0xFF303F9F), // Indigo
    Color(0xFF1976D2), // Blue
    // Row 2: Blues to Greens
    Color(0xFF0288D1), // Light Blue
    Color(0xFF0097A7), // Cyan
    Color(0xFF00796B), // Teal
    Color(0xFF388E3C), // Green
    Color(0xFF689F38), // Light Green
    Color(0xFFAFB42B), // Lime
    // Row 3: Yellows to Browns
    Color(0xFFFBC02D), // Yellow
    Color(0xFFFFA000), // Amber
    Color(0xFFF57C00), // Orange
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF5D4037), // Brown
    Color(0xFF616161), // Grey
    // Row 4: Neutrals
    Color(0xFF455A64), // Blue Grey
    Color(0xFF212121), // Dark Grey
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFFF5F5F5), // Light Grey
    Color(0xFF9E9E9E), // Medium Grey
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(text: _colorToHex(_selectedColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '').toUpperCase();
    if (hex.length == 6) {
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexController.text = _colorToHex(color);
    });
  }

  void _updateRGB({int? r, int? g, int? b}) {
    final newColor = Color.fromARGB(
      255,
      r ?? _selectedColor.r.toInt(),
      g ?? _selectedColor.g.toInt(),
      b ?? _selectedColor.b.toInt(),
    );
    _updateColor(newColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title ?? 'Select Color'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color preview
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  '#${_colorToHex(_selectedColor)}',
                  style: TextStyle(
                    color: _selectedColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hex input
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: 'Hex Color',
                prefixText: '#',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _onHexChanged,
            ),

            const SizedBox(height: 16),

            // RGB sliders
            _buildSlider(
              'R',
              _selectedColor.r.toInt(),
              Colors.red,
              (v) => _updateRGB(r: v),
            ),
            _buildSlider(
              'G',
              _selectedColor.g.toInt(),
              Colors.green,
              (v) => _updateRGB(g: v),
            ),
            _buildSlider(
              'B',
              _selectedColor.b.toInt(),
              Colors.blue,
              (v) => _updateRGB(b: v),
            ),

            const SizedBox(height: 16),

            // Preset colors grid
            const Text(
              'Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetColors.map((c) => _buildColorChip(c)).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    int value,
    Color activeColor,
    void Function(int) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.2),
              inactiveTrackColor: activeColor.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(Color color) {
    final isSelected = color.toARGB32() == _selectedColor.toARGB32();
    final isLight = color.computeLuminance() > 0.8;

    return GestureDetector(
      onTap: () => _updateColor(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isLight ? Colors.grey.shade400 : Colors.transparent),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
