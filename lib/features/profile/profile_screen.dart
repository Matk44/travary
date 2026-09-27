import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../state/travel_store.dart';
import '../premium/plus_card.dart';
import 'card_gallery_screen.dart';

/// Account and settings. Sign-in and Travary Plus will live here.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final preview = store.previewNow;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: TravarySpace.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, TravarySpace.lg, TravarySpace.gutter, 0),
            child: Text('Profile', style: TravaryText.display),
          ),
          const SizedBox(height: TravarySpace.lg),
          const PlusCard(),
          const SectionLabel('Your data'),
          ListTile(
            leading: Icon(store.isDemo ? Icons.science_outlined : Icons.cloud_done_outlined),
            title: Text(store.repository.label),
            subtitle: Text(
              store.isDemo
                  ? 'Sample trips for design and testing. Changes last until the app restarts.'
                  : 'Saved to the cloud and available offline.',
            ),
          ),
          if (store.isDemo)
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset sample trips'),
              onTap: store.resetDemoData,
            ),
          if (kDebugMode) ...[
            const SectionLabel('Design tools'),
            const TestPlanSwitcher(),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('Card gallery'),
              subtitle: const Text('Every card, size and state in any trip theme'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardGalleryScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.more_time_rounded),
              title: const Text('Preview a different time'),
              subtitle: Text(
                preview == null
                    ? 'See cards before, during and after their time'
                    : 'Showing ${formatDayShort(LocalDate.fromDateTime(preview))} at '
                          '${formatClock(ClockTime.fromDateTime(preview))}',
              ),
              trailing: preview == null
                  ? null
                  : IconButton(
                      tooltip: 'Back to real time',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => store.previewNow = null,
                    ),
              onTap: () => _pickPreviewTime(context, store),
            ),
          ],
          const SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.luggage_outlined),
            title: Text('Travary'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPreviewTime(BuildContext context, TravelStore store) async {
    final now = store.now;
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    store.previewNow = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
