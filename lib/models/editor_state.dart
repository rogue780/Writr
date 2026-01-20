import 'scrivener_project.dart';

/// Represents the state of an editor pane.
class EditorPaneState {
  /// The document currently being edited in this pane
  final BinderItem? document;

  /// Scroll position in this pane
  final double scrollPosition;

  /// Whether this pane is currently focused
  final bool isFocused;

  /// Cursor position in the document
  final int cursorPosition;

  const EditorPaneState({
    this.document,
    this.scrollPosition = 0.0,
    this.isFocused = false,
    this.cursorPosition = 0,
  });

  EditorPaneState copyWith({
    BinderItem? document,
    double? scrollPosition,
    bool? isFocused,
    int? cursorPosition,
  }) {
    return EditorPaneState(
      document: document ?? this.document,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isFocused: isFocused ?? this.isFocused,
      cursorPosition: cursorPosition ?? this.cursorPosition,
    );
  }
}

/// Split orientation for the editor
enum SplitOrientation {
  horizontal,
  vertical,
}

/// Represents the overall split editor state
class SplitEditorState {
  /// Whether split mode is enabled
  final bool isSplitEnabled;

  /// The orientation of the split
  final SplitOrientation orientation;

  /// The position of the split divider (0.0 to 1.0)
  final double splitPosition;

  /// State of the primary (left/top) pane
  final EditorPaneState primaryPane;

  /// State of the secondary (right/bottom) pane
  final EditorPaneState secondaryPane;

  const SplitEditorState({
    this.isSplitEnabled = false,
    this.orientation = SplitOrientation.vertical,
    this.splitPosition = 0.5,
    this.primaryPane = const EditorPaneState(isFocused: true),
    this.secondaryPane = const EditorPaneState(),
  });

  SplitEditorState copyWith({
    bool? isSplitEnabled,
    SplitOrientation? orientation,
    double? splitPosition,
    EditorPaneState? primaryPane,
    EditorPaneState? secondaryPane,
  }) {
    return SplitEditorState(
      isSplitEnabled: isSplitEnabled ?? this.isSplitEnabled,
      orientation: orientation ?? this.orientation,
      splitPosition: splitPosition ?? this.splitPosition,
      primaryPane: primaryPane ?? this.primaryPane,
      secondaryPane: secondaryPane ?? this.secondaryPane,
    );
  }

  /// Toggle split mode on/off
  SplitEditorState toggleSplit() {
    return copyWith(isSplitEnabled: !isSplitEnabled);
  }

  /// Toggle split orientation
  SplitEditorState toggleOrientation() {
    return copyWith(
      orientation: orientation == SplitOrientation.horizontal
          ? SplitOrientation.vertical
          : SplitOrientation.horizontal,
    );
  }

  /// Set focus to primary pane
  SplitEditorState focusPrimary() {
    return copyWith(
      primaryPane: primaryPane.copyWith(isFocused: true),
      secondaryPane: secondaryPane.copyWith(isFocused: false),
    );
  }

  /// Set focus to secondary pane
  SplitEditorState focusSecondary() {
    return copyWith(
      primaryPane: primaryPane.copyWith(isFocused: false),
      secondaryPane: secondaryPane.copyWith(isFocused: true),
    );
  }

  /// Get the currently focused pane
  EditorPaneState get focusedPane =>
      primaryPane.isFocused ? primaryPane : secondaryPane;

  /// Check if a document is open in either pane
  bool isDocumentOpen(String documentId) {
    return primaryPane.document?.id == documentId ||
        secondaryPane.document?.id == documentId;
  }
}
