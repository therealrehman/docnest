import 'package:docnest/app/app.dart';
import 'package:docnest/features/documents/data/document_record.dart';
import 'package:docnest/features/documents/data/document_store.dart';
import 'package:docnest/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake store so tests never touch the real file system or plugins.
class _FakeDocumentStore extends DocumentStore {
  @override
  Future<List<DocumentRecord>> loadAll() async => [];
}

void main() {
  testWidgets('first launch goes from splash to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: DocNestApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('All Your Documents in One Place'), findsOneWidget);
  });

  testWidgets('home shows empty state when no documents exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentStoreProvider.overrideWithValue(_FakeDocumentStore()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello!'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
  });
}
