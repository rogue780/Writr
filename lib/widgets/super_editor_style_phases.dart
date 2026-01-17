import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

/// Sanitizes invalid text selections to avoid Flutter assertions in
/// `TextPainter.getBoxesForSelection()` when selection offsets temporarily
/// fall outside the valid range.
class ClampInvalidTextSelectionStylePhase extends SingleColumnLayoutStylePhase {
  @override
  SingleColumnLayoutViewModel style(Document document, SingleColumnLayoutViewModel viewModel) {
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final previousViewModel in viewModel.componentViewModels)
          _sanitizeTextSelection(previousViewModel.copy()),
      ],
    );
  }

  SingleColumnLayoutComponentViewModel _sanitizeTextSelection(
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! TextComponentViewModel) {
      return viewModel;
    }

    final selection = viewModel.selection;
    if (selection == null || selection.isValid) {
      return viewModel;
    }

    if (selection.baseOffset == -1 && selection.extentOffset == -1) {
      viewModel.selection = null;
      return viewModel;
    }

    final maxOffset = viewModel.text.length;
    final clampedBase = selection.baseOffset.clamp(0, maxOffset).toInt();
    final clampedExtent = selection.extentOffset.clamp(0, maxOffset).toInt();

    final clampedSelection = TextSelection(
      baseOffset: clampedBase,
      extentOffset: clampedExtent,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );

    viewModel.selection = clampedSelection.isValid ? clampedSelection : null;
    return viewModel;
  }
}

