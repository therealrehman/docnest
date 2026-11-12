import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';

/// Reminders tab with Upcoming / Overdue / Completed tabs.
/// Reminders are created only from user-confirmed dates (Phase 5).
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DocNestSpacing.screen,
                DocNestSpacing.m,
                DocNestSpacing.screen,
                0,
              ),
              child: Text('Reminders', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: DocNestSpacing.s),
            const TabBar(
              tabs: [
                Tab(text: 'Upcoming'),
                Tab(text: 'Overdue'),
                Tab(text: 'Completed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _emptyTab(
                    'Reminders are created only from dates you confirm. They will appear here once documents can be added.',
                  ),
                  _emptyTab('Overdue reminders show here after you confirm a date.'),
                  _emptyTab('Completed reminders show here.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTab(String message) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DocNestSpacing.screen,
        DocNestSpacing.m,
        DocNestSpacing.screen,
        DocNestSpacing.section,
      ),
      children: [
        EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'No reminders here',
          message: message,
        ),
      ],
    );
  }
}
