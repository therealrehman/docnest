import 'package:docnest/features/scan/application/scan_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reorder moves a page and rotate cycles through 0 to 3', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(scanSessionProvider.notifier);

    notifier.addPage('a.jpg');
    notifier.addPage('b.jpg');
    notifier.addPage('c.jpg');

    // Move the first page to the end, the same way a drag to the bottom reports it.
    notifier.reorder(0, 3);
    final paths = container.read(scanSessionProvider).map((p) => p.path).toList();
    expect(paths, ['b.jpg', 'c.jpg', 'a.jpg']);

    final firstId = container.read(scanSessionProvider).first.id;
    for (var i = 0; i < 4; i++) {
      notifier.rotatePage(firstId);
    }
    expect(container.read(scanSessionProvider).first.quarterTurns, 0);
  });

  test('retake replaces the photo and resets rotation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(scanSessionProvider.notifier);

    notifier.addPage('old.jpg');
    final id = container.read(scanSessionProvider).single.id;
    notifier.rotatePage(id);
    notifier.replacePage(id, 'new.jpg');

    final page = container.read(scanSessionProvider).single;
    expect(page.path, 'new.jpg');
    expect(page.quarterTurns, 0);
  });
}
