import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scan_page.dart';

/// Pages captured in the current scan, in order. Kept in memory until the user
/// saves them as a PDF or discards them.
class ScanSessionController extends Notifier<List<ScanPage>> {
  int _sequence = 0;

  @override
  List<ScanPage> build() => const [];

  void addPage(String path) {
    state = [...state, ScanPage(id: _newId(), path: path)];
  }

  /// Replaces the photo of one page (retake). The rotation resets to 0.
  void replacePage(String pageId, String path) {
    state = [
      for (final page in state)
        if (page.id == pageId) page.copyWith(path: path, quarterTurns: 0) else page,
    ];
  }

  void rotatePage(String pageId) {
    state = [
      for (final page in state)
        if (page.id == pageId)
          page.copyWith(quarterTurns: (page.quarterTurns + 1) % 4)
        else
          page,
    ];
  }

  void removePage(String pageId) {
    state = state.where((page) => page.id != pageId).toList();
  }

  /// Same index rules as ReorderableListView.onReorder.
  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = list.removeAt(oldIndex);
    list.insert(target, moved);
    state = list;
  }

  void clear() {
    state = const [];
  }

  String _newId() {
    _sequence++;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$_sequence';
  }
}

final scanSessionProvider =
    NotifierProvider<ScanSessionController, List<ScanPage>>(ScanSessionController.new);
