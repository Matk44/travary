import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/home_shell.dart';
import '../../design/tokens.dart';
import '../../logic/onboarding_rules.dart';
import '../../state/onboarding_store.dart';
import '../../state/app_session.dart';
import '../../state/travel_store.dart';
import '../sharing/join_trip_sheet.dart';
import '../trips/trip_screen.dart';
import 'onboarding_route.dart';
import 'onboarding_pass_screen.dart';
import 'onboarding_screen.dart';

/// First-run setup, or straight home. Onboarding shows for an account that
/// hasn't been through it: not on this phone (the local setup), not on any
/// other (`users/{uid}.onboardingCompleted`, set by finishing it or signing
/// in) and with no plans yet. A setup in progress on this phone resumes.
/// Ordinary demo runs keep their home; the preview define forces the flow.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, this.force = const bool.fromEnvironment('TRAVARY_PREVIEW_ONBOARDING')});
  final bool force;
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _finished = false;
  int _run = 0;
  bool _accountHandoffScheduled = false;
  AppSession? _session;
  bool _joining = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<AppSession?>();
    if (session != _session) {
      _session?.removeListener(_inviteArrived);
      _session = session?..addListener(_inviteArrived);
      _inviteArrived();
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_inviteArrived);
    super.dispose();
  }

  /// An invite link opened the app (`travary.app/join/ABC234`): straight
  /// to joining that trip, with its code filled in. Someone new skips
  /// setup altogether; the trip opens once they're on it.
  void _inviteArrived() {
    if (_joining || _session?.pendingInviteCode == null) return;
    _joining = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final code = _session?.takeInviteCode();
      if (code == null || !mounted) {
        _joining = false;
        return;
      }
      final joined = await showJoinTripSheet(context, code: code);
      _joining = false;
      if (joined == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You\'ve joined ${joined.title}')));
      if (!_finished) {
        await context.read<OnboardingStore>().complete();
        if (!mounted) return;
        setState(() => _finished = true);
      }
      await openJoinedTrip(context, joined.tripId);
    });
  }

  /// "Signed in with Google…", said on the pass desk rather than in a
  /// snackbar over its buttons.
  String? _handoffNotice;

  void _finish(String? tripId) {
    setState(() => _finished = true);
    if (tripId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(tripId));
  }

  void _open(String tripId) {
    if (mounted && context.read<TravelStore>().plan(tripId) != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)));
    }
  }

  /// Onboarding's sign-in switched to an existing account, which now has
  /// the guest's holiday: its pass desk (when the sign-in came just before
  /// it), then the holiday itself.
  Future<void> _handoff(AppSession session) async {
    final tripId = session.takeTripToOpenAfterSignIn();
    final offer = session.takeOfferAfterSignIn();
    if (tripId == null || !mounted) return;
    setState(() => _finished = true);
    if (offer && context.read<TravelStore>().plan(tripId) != null) {
      await Navigator.of(
        context,
      ).push(onboardingFadeRoute((_) => OnboardingPassScreen(tripId: tripId, notice: _handoffNotice)));
    }
    _open(tripId);
  }

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelStore>();
    final session = context.read<AppSession?>();
    if (session?.tripToOpenAfterSignIn != null) {
      // Before the home screen takes it for a snackbar.
      if (session!.offerAfterSignIn) _handoffNotice ??= session.takeNotice();
      if (!_accountHandoffScheduled && !travel.isLoading) {
        _accountHandoffScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _handoff(session));
      }
      return const HomeShell();
    }
    final setup = context.watch<OnboardingStore>();
    if (setup.run != _run) {
      // Restarted from Design tools: play it again from the top.
      _run = setup.run;
      _finished = false;
    }
    final force = widget.force || setup.replaying;
    if (_finished || (travel.isDemo && !force)) return const HomeShell();
    if (setup.loading || travel.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (setup.error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TravarySpace.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(setup.error!, style: TravaryText.body),
                const SizedBox(height: 16),
                FilledButton(onPressed: setup.load, child: const Text('Try again')),
                TextButton(onPressed: () => _finish(null), child: const Text('Open my saved plans')),
              ],
            ),
          ),
        ),
      );
    }
    if (!force &&
        !onboardingNeeded(
          draft: setup.draft,
          hasPlans: travel.hasAnything,
          completedElsewhere: setup.completedElsewhere,
        )) {
      _finished = true;
      return const HomeShell();
    }
    return OnboardingScreen(key: ValueKey(setup.run), onFinished: _finish);
  }
}
