import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../logic/travi_cameos.dart';
import '../../state/reminders_store.dart';

/// Turns reminders on, asking the phone if it hasn't been asked. If the
/// phone says no, says where to turn them on instead.
Future<void> turnOnReminders(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final allowed = await context.read<RemindersStore>().turnOn();
  if (!allowed) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Notifications are off for Travary. You can turn them on in Settings.')),
    );
  }
}

/// On a trip's page, once it has a booking: Travi offering a nudge each
/// morning. Only "Yes" asks the phone; "Not now" puts it away for good
/// (Profile keeps the switch).
class ReminderOffer extends StatelessWidget {
  const ReminderOffer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final reminders = context.read<RemindersStore>();
    return PaperPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TravarySpace.md, TravarySpace.md, TravarySpace.lg, TravarySpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: TraviCameo(moment: TraviMoment.hello, height: 72, close: true)),
                const SizedBox(width: TravarySpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A nudge each morning?', style: TravaryText.ledgerTitle.copyWith(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                        'Your day’s plan each morning of the trip, and a reminder before each booking. '
                        'Free, on this phone.',
                        style: TravaryText.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: TravarySpace.xs,
              children: [
                TextButton(
                  key: const ValueKey('reminders-not-now'),
                  onPressed: reminders.decline,
                  child: Text('Not now', style: TravaryText.label.copyWith(color: TravaryColors.inkSoft)),
                ),
                TextButton(
                  key: const ValueKey('reminders-yes'),
                  onPressed: () => turnOnReminders(context),
                  child: Text('Yes, remind me', style: TravaryText.label.copyWith(color: colors.ink)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
