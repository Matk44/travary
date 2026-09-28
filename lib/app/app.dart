import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/art_pack_service.dart';
import '../data/smart_import_service.dart';
import '../data/visual_profile_service.dart';
import '../design/tokens.dart';
import '../state/premium_store.dart';
import '../state/travel_store.dart';
import 'bootstrap.dart';
import 'home_shell.dart';
import 'trip_chrome_scope.dart';

class TravaryApp extends StatelessWidget {
  const TravaryApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SmartImportService>.value(value: dependencies.smartImport),
        Provider<VisualProfileService?>.value(value: dependencies.visualProfiles),
        // Owned by bootstrap for the app's lifetime.
        ChangeNotifierProvider<ArtPackManager>.value(value: dependencies.artPacks),
        ChangeNotifierProvider(
          create: (context) => TravelStore(
            repository: dependencies.repository,
            artCatalog: dependencies.artCatalog,
            artPacks: context.read<ArtPackManager>(),
            visualProfiles: context.read<VisualProfileService?>(),
            attachments: dependencies.attachments,
            backup: dependencies.backup,
            sharing: dependencies.sharing,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final travel = context.read<TravelStore>();
            // Shares the travel clock, so "Preview a different time" also
            // previews trial and Trip Pass expiry.
            return PremiumStore(purchases: dependencies.purchases, clock: () => travel.now);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Travary',
        debugShowCheckedModeBanner: false,
        theme: buildTravaryTheme(),
        // Every screen, pushed ones included, shares the trip's palette.
        builder: (context, child) => TripChromeScope(child: child!),
        home: const HomeShell(),
      ),
    );
  }
}

/// Shown instead of the app when startup fails, with a hint for fixing it.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message, this.hint});

  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTravaryTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TravarySpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: TravaryColors.coral),
                const SizedBox(height: TravarySpace.lg),
                Text(message, style: TravaryText.title),
                if (hint != null) ...[
                  const SizedBox(height: TravarySpace.sm),
                  Text(hint!, style: TravaryText.bodySoft),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
