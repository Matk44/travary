import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/tokens.dart';
import '../state/premium_store.dart';
import '../state/travel_store.dart';
import 'bootstrap.dart';
import 'home_shell.dart';

class TravaryApp extends StatelessWidget {
  const TravaryApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TravelStore(
            repository: dependencies.repository,
            artCatalog: dependencies.artCatalog,
            attachments: dependencies.attachments,
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
