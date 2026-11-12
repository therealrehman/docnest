import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/preferences/theme_mode_controller.dart';

const _comingLater = <(IconData, String)>[
  (Icons.security_rounded, 'Security & privacy'),
  (Icons.backup_rounded, 'Backup & restore'),
  (Icons.notifications_outlined, 'Notifications'),
  (Icons.info_outline_rounded, 'About DocNest'),
];

/// Settings tab. Appearance and filing rules work. Other sections come in later phases.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DocNestSpacing.screen,
          DocNestSpacing.m,
          DocNestSpacing.screen,
          DocNestSpacing.section,
        ),
        children: [
          Text('Settings', style: theme.textTheme.headlineMedium),
          const SizedBox(height: DocNestSpacing.section),
          Text('Appearance', style: theme.textTheme.titleLarge),
          const SizedBox(height: DocNestSpacing.s),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).setMode(selection.first);
              },
            ),
          ),
          const SizedBox(height: DocNestSpacing.section),
          Text('Organize', style: theme.textTheme.titleLarge),
          const SizedBox(height: DocNestSpacing.xs),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Filing rules'),
            subtitle: const Text('Words that make DocNest suggest a folder'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.filingRules),
          ),
          const SizedBox(height: DocNestSpacing.section),
          Text('More settings', style: theme.textTheme.titleLarge),
          const SizedBox(height: DocNestSpacing.xs),
          for (final item in _comingLater)
            ListTile(
              enabled: false,
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.$1),
              title: Text(item.$2),
              subtitle: const Text('Coming in a later phase'),
            ),
        ],
      ),
    );
  }
}
