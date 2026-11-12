import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';
import '../folders/application/folders_controller.dart';
import '../folders/data/folder_record.dart';
import 'application/document_filter.dart';
import 'application/documents_controller.dart';
import 'application/import_flow.dart';
import 'data/document_record.dart';
import 'presentation/document_tile.dart';

/// Documents tab: search, a view filter (All, Favorites, Archived), a type filter
/// and a tag filter.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchController = TextEditingController();
  DocumentView _view = DocumentView.all;
  TypeFilter _type = TypeFilter.any;
  String? _tag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _searchText => _searchController.text;

  DocumentQuery get _query => DocumentQuery(
        view: _view,
        text: _searchText,
        type: _type,
        tag: _tag,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = ref.watch(documentsProvider);
    final items = docs.valueOrNull ?? const <DocumentRecord>[];
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <FolderRecord>[];
    final folderNames = {for (final folder in folders) folder.id: folder.name};

    // Keep a selected tag visible even if no active document has it any more,
    // so the user can always clear it.
    final tags = activeTags(items);
    final tagChoices = [
      ...tags,
      if (_tag != null && !tags.contains(_tag)) _tag!,
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => runImport(context, ref),
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('Import'),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DocNestSpacing.screen,
            DocNestSpacing.m,
            DocNestSpacing.screen,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Documents', style: theme.textTheme.headlineMedium),
                  ),
                  IconButton(
                    tooltip: 'Folders',
                    icon: const Icon(Icons.folder_outlined),
                    onPressed: () => context.push(AppRoutes.folders),
                  ),
                ],
              ),
              const SizedBox(height: DocNestSpacing.s),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search name, tag or folder',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: DocNestSpacing.s),
              SegmentedButton<DocumentView>(
                segments: const [
                  ButtonSegment(value: DocumentView.all, label: Text('All')),
                  ButtonSegment(value: DocumentView.favorites, label: Text('Favorites')),
                  ButtonSegment(value: DocumentView.archived, label: Text('Archived')),
                ],
                selected: {_view},
                onSelectionChanged: (selection) => setState(() => _view = selection.first),
              ),
              const SizedBox(height: DocNestSpacing.xs),
              Wrap(
                spacing: DocNestSpacing.xs,
                children: [
                  for (final type in TypeFilter.values)
                    ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              if (tagChoices.isNotEmpty) ...[
                const SizedBox(height: DocNestSpacing.xs),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final tag in tagChoices)
                        Padding(
                          padding: const EdgeInsets.only(right: DocNestSpacing.xs),
                          child: FilterChip(
                            label: Text(tag),
                            selected: _tag == tag,
                            onSelected: (selected) =>
                                setState(() => _tag = selected ? tag : null),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DocNestSpacing.s),
              Expanded(child: _buildList(docs, folderNames)),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TypeFilter type) => switch (type) {
        TypeFilter.any => 'All types',
        TypeFilter.pdf => 'PDF',
        TypeFilter.image => 'Images',
      };

  EmptyState _emptyState() {
    if (_searchText.trim().isNotEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try another name, tag or folder, or clear the search.',
      );
    }
    if (_tag != null || _type != TypeFilter.any) {
      return const EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nothing matches these filters',
        message: 'Clear a filter to see more documents.',
      );
    }
    return switch (_view) {
      DocumentView.all => const EmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No documents yet',
          message: 'Tap Import to add PDFs or images from your phone.',
        ),
      DocumentView.favorites => const EmptyState(
          icon: Icons.star_outline_rounded,
          title: 'No favorites yet',
          message: 'Open a document and tap Add to favorites.',
        ),
      DocumentView.archived => const EmptyState(
          icon: Icons.archive_outlined,
          title: 'Nothing archived',
          message: 'Archived documents leave the main list but stay on this phone.',
        ),
    };
  }

  Widget _buildList(
    AsyncValue<List<DocumentRecord>> docs,
    Map<String, String> folderNames,
  ) {
    return docs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load documents',
            message: 'Please try again.',
          ),
          const SizedBox(height: DocNestSpacing.s),
          Center(
            child: TextButton(
              onPressed: () => ref.invalidate(documentsProvider),
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
      data: (items) {
        final visible = filterDocuments(items, _query, folderNames);
        if (visible.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [_emptyState()],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: visible.length,
          separatorBuilder: (context, index) => const SizedBox(height: DocNestSpacing.s),
          itemBuilder: (context, index) {
            final record = visible[index];
            return DocumentTile(
              record: record,
              onTap: () => context.push(AppRoutes.documentDetails(record.id)),
            );
          },
        );
      },
    );
  }
}
