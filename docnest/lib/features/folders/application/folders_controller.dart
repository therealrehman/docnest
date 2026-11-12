import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/application/documents_controller.dart';
import '../../documents/application/filing_rules_controller.dart';
import '../../documents/data/document_store.dart';
import '../data/folder_record.dart';

/// Folder list. Create, rename and delete go through the store, then reload.
class FoldersController extends AsyncNotifier<List<FolderRecord>> {
  @override
  Future<List<FolderRecord>> build() {
    return ref.read(documentStoreProvider).loadFolders();
  }

  Future<void> create(String name) => _change((store) => store.createFolder(name));

  Future<void> rename(FolderRecord folder, String name) =>
      _change((store) => store.renameFolder(folder, name));

  /// Documents in the folder are kept and become unfiled, so the documents list reloads too.
  /// Personal filing rules that pointed to the folder are removed by the store, so they reload.
  Future<void> delete(FolderRecord folder) async {
    await _change((store) => store.deleteFolder(folder));
    ref.invalidate(documentsProvider);
    ref.invalidate(filingRulesProvider);
  }

  Future<void> _change(Future<void> Function(DocumentStore store) action) async {
    final store = ref.read(documentStoreProvider);
    await action(store);
    state = await AsyncValue.guard(store.loadFolders);
  }
}

final foldersProvider =
    AsyncNotifierProvider<FoldersController, List<FolderRecord>>(FoldersController.new);
