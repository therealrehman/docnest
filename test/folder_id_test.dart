import 'package:docnest/core/constants/default_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built-in folder ids are stable and URL-safe', () {
    expect(builtInFolderId('Identity & Travel'), 'builtin-identity-travel');
    expect(builtInFolderId('Home & Property'), 'builtin-home-property');
    expect(builtInFolderId('Other'), 'builtin-other');
  });

  test('every default category has a unique folder id', () {
    final ids = defaultCategories.map((c) => builtInFolderId(c.name)).toSet();
    expect(ids.length, defaultCategories.length);
  });
}
