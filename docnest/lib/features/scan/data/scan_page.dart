/// One photo in the current scan session.
class ScanPage {
  const ScanPage({
    required this.id,
    required this.path,
    this.quarterTurns = 0,
  });

  final String id;

  /// Original photo from the camera. It stays in the temporary cache until the
  /// PDF is saved or the scan is discarded.
  final String path;

  /// Clockwise 90 degree steps (0 to 3) chosen by the user. Applied when the PDF is built.
  final int quarterTurns;

  ScanPage copyWith({String? path, int? quarterTurns}) {
    return ScanPage(
      id: id,
      path: path ?? this.path,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    );
  }
}
