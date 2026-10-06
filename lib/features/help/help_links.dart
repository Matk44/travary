import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/domain.dart';

/// Opens one of Travary's pages ([TravaryLinks]) in the in-app browser.
/// Says so if it can't, with the address to try instead.
Future<void> openTravaryPage(BuildContext context, Uri page) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await _launch(page, LaunchMode.inAppBrowserView);
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text('Couldn\'t open the page. It\'s at $page')));
  }
}

/// Starts an email to support in the phone's mail app.
Future<void> emailSupport(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await _launch(TravaryLinks.email(), LaunchMode.externalApplication);
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No mail app found. Email us at ${TravaryLinks.supportEmail}')),
    );
  }
}

Future<bool> _launch(Uri uri, LaunchMode mode) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}
