/// Parsed result from a Markdown file with frontmatter.
class MarkdownDocument {
  const MarkdownDocument({
    required this.frontmatter,
    required this.content,
  });

  /// Key-value pairs from the YAML frontmatter.
  final Map<String, dynamic> frontmatter;

  /// The markdown content after the frontmatter.
  final String content;

  /// Get a string value from frontmatter, or null if not present.
  String? getString(String key) {
    final value = frontmatter[key];
    return value?.toString();
  }

  /// Get an int value from frontmatter, or null if not present.
  int? getInt(String key) {
    final value = frontmatter[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Get a bool value from frontmatter, or null if not present.
  bool? getBool(String key) {
    final value = frontmatter[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }
}

/// Parse a Markdown file with optional YAML frontmatter.
///
/// Returns a [MarkdownDocument] with the parsed frontmatter and content.
/// If there's no frontmatter, returns empty frontmatter map and full content.
MarkdownDocument parseMarkdownWithFrontmatter(String source) {
  final trimmed = source.trimLeft();

  // Check for frontmatter delimiter
  if (!trimmed.startsWith('---')) {
    return MarkdownDocument(frontmatter: const {}, content: source);
  }

  // Find the closing delimiter
  final afterFirst = trimmed.substring(3);
  final endIndex = afterFirst.indexOf('\n---');

  if (endIndex == -1) {
    // No closing delimiter - treat as regular content
    return MarkdownDocument(frontmatter: const {}, content: source);
  }

  // Extract frontmatter YAML
  final yamlContent = afterFirst.substring(0, endIndex).trim();

  // Parse simple YAML (key: value pairs, one per line)
  final frontmatter = _parseSimpleYaml(yamlContent);

  // Extract content after frontmatter
  // Skip the closing --- and any trailing newline
  var contentStart = endIndex + 4; // length of '\n---'
  while (contentStart < afterFirst.length &&
      (afterFirst[contentStart] == '\n' || afterFirst[contentStart] == '\r')) {
    contentStart++;
  }
  final content = afterFirst.substring(contentStart);

  return MarkdownDocument(frontmatter: frontmatter, content: content);
}

/// Simple YAML parser for frontmatter.
///
/// Handles:
/// - key: value (strings, numbers, booleans)
/// - key: | (multiline strings)
/// - Quoted strings
Map<String, dynamic> _parseSimpleYaml(String yaml) {
  final result = <String, dynamic>{};
  final lines = yaml.split('\n');

  String? currentKey;
  StringBuffer? multilineBuffer;
  int? multilineIndent;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Handle multiline continuation
    if (multilineBuffer != null && currentKey != null) {
      if (line.isEmpty || line.startsWith(' ') || line.startsWith('\t')) {
        // Calculate actual content by removing the expected indentation
        final contentLine = multilineIndent != null && line.length > multilineIndent
            ? line.substring(multilineIndent)
            : line.trimLeft();
        if (multilineBuffer.isNotEmpty) {
          multilineBuffer.write('\n');
        }
        multilineBuffer.write(contentLine);
        continue;
      } else {
        // End of multiline
        result[currentKey] = multilineBuffer.toString();
        multilineBuffer = null;
        currentKey = null;
        multilineIndent = null;
      }
    }

    // Skip empty lines and comments outside multiline
    if (line.trim().isEmpty || line.trim().startsWith('#')) {
      continue;
    }

    // Parse key: value
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) continue;

    final key = line.substring(0, colonIndex).trim();
    var value = line.substring(colonIndex + 1).trim();

    // Check for multiline indicator
    if (value == '|' || value == '|-') {
      currentKey = key;
      multilineBuffer = StringBuffer();
      // Determine indentation of next line for multiline content
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        multilineIndent = nextLine.length - nextLine.trimLeft().length;
      }
      continue;
    }

    // Handle quoted strings
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
      result[key] = value;
      continue;
    }

    // Try to parse as number
    final intValue = int.tryParse(value);
    if (intValue != null) {
      result[key] = intValue;
      continue;
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      result[key] = doubleValue;
      continue;
    }

    // Try to parse as boolean
    if (value.toLowerCase() == 'true') {
      result[key] = true;
      continue;
    }
    if (value.toLowerCase() == 'false') {
      result[key] = false;
      continue;
    }

    // Store as string
    result[key] = value;
  }

  // Handle any remaining multiline content
  if (multilineBuffer != null && currentKey != null) {
    result[currentKey] = multilineBuffer.toString();
  }

  return result;
}

/// Write a Markdown document with YAML frontmatter.
///
/// Returns the formatted string with frontmatter header and content.
String writeMarkdownWithFrontmatter({
  required Map<String, dynamic> frontmatter,
  required String content,
}) {
  if (frontmatter.isEmpty) {
    return content;
  }

  final buffer = StringBuffer();
  buffer.writeln('---');

  for (final entry in frontmatter.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value == null) continue;

    if (value is String && value.contains('\n')) {
      // Multiline string
      buffer.writeln('$key: |');
      for (final line in value.split('\n')) {
        buffer.writeln('  $line');
      }
    } else if (value is String && _needsQuoting(value)) {
      // Quote strings with special characters
      final escaped = value.replaceAll('"', r'\"');
      buffer.writeln('$key: "$escaped"');
    } else {
      buffer.writeln('$key: $value');
    }
  }

  buffer.writeln('---');
  buffer.writeln();
  buffer.write(content);

  return buffer.toString();
}

/// Check if a string value needs to be quoted in YAML.
bool _needsQuoting(String value) {
  if (value.isEmpty) {
    return true;
  }
  if (value.startsWith(' ') || value.endsWith(' ')) {
    return true;
  }
  if (value.contains(':') || value.contains('#')) {
    return true;
  }
  if (value.contains('"') || value.contains("'")) {
    return true;
  }

  // Check if it looks like a number or boolean
  if (int.tryParse(value) != null) {
    return true;
  }
  if (double.tryParse(value) != null) {
    return true;
  }
  if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
    return true;
  }
  if (value.toLowerCase() == 'null') {
    return true;
  }

  return false;
}
