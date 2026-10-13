import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/art/art_slots.dart';
import '../../design/cards/card_parts.dart';
import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/common.dart';
import '../../domain/domain.dart';
import '../../logic/formatters.dart';
import '../../state/onboarding_store.dart';
import '../../state/reminders_store.dart';
import '../../state/travel_store.dart';
import '../account/account_card.dart';
import '../help/help_links.dart';
import '../premium/plus_card.dart';
import '../reminders/reminder_offer.dart';
import '../travel_documents/document_actions.dart';
import 'card_gallery_screen.dart';
import 'flight_status_test_screen.dart';
import 'travi_cameos_screen.dart';

/// Account and settings: signing in, the Annual Pass, travel documents,
/// reminders.
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
          const AccountCard(),
          const SizedBox(height: TravarySpace.lg),
          const PlusCard(),
          const SectionLabel('Your documents'),
          ListTile(
            leading: SlotIcon(
              icon: TravaryChrome.of(context).slots.icon(IconSlot.passport),
              color: TravaryColors.ink,
              size: 26,
            ),
            title: const Text('Travel documents'),
            subtitle: const Text('Passports, visas and insurance, kept on this phone only'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openTravelDocuments(context),
          ),
          if (context.watch<RemindersStore?>() case final reminders? when reminders.available) ...[
            const SectionLabel('Reminders'),
            SwitchListTile(
              key: const ValueKey('profile-reminders'),
              secondary: const Icon(Icons.notifications_none_rounded),
              title: const Text('Reminders'),
              subtitle: Text(
                reminders.blocked
                    ? 'Notifications are off for Travary. Turn them on in Settings.'
                    : 'Your day’s plan each morning of a trip, and a nudge before each booking. Free.',
              ),
              value: reminders.on,
              onChanged: (on) => on ? turnOnReminders(context) : reminders.turnOff(),
            ),
          ],
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
              key: const ValueKey('design-restart-onboarding'),
              leading: const Icon(Icons.replay_rounded),
              title: const Text('Restart onboarding'),
              subtitle: const Text('From Travi rolling in. Holidays it made before are kept.'),
              onTap: () => context.read<OnboardingStore>().restart(),
            ),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('Card gallery'),
              subtitle: const Text('Every card, size and state in any trip theme'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CardGalleryScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.luggage_outlined),
              title: const Text('Travi cameos'),
              subtitle: const Text('Where Travi turns up around the app'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TraviCameosScreen())),
            ),
            if (store.flightStatus != null)
              ListTile(
                leading: const Icon(Icons.flight_takeoff_rounded),
                title: const Text('Flight status test'),
                subtitle: const Text('Live gate and delays for any real flight'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlightStatusTestScreen())),
              ),
            if (context.watch<RemindersStore?>() case final reminders? when reminders.on)
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Send a test reminder'),
                subtitle: const Text('The next morning’s plan, in five seconds. Leave the app to see it.'),
                onTap: reminders.sendTest,
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
          const SectionLabel('Help and legal'),
          ListTile(
            key: const ValueKey('help-support'),
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help and support'),
            subtitle: const Text('Answers to common questions'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => openTravaryPage(context, TravaryLinks.support),
          ),
          ListTile(
            key: const ValueKey('help-email'),
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Email us'),
            subtitle: const Text(TravaryLinks.supportEmail),
            onTap: () => emailSupport(context),
          ),
          ListTile(
            key: const ValueKey('help-privacy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => openTravaryPage(context, TravaryLinks.privacy),
          ),
          ListTile(
            key: const ValueKey('help-terms'),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => openTravaryPage(context, TravaryLinks.terms),
          ),
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
