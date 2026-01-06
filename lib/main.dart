// Inhaus_Brain
// Copyright (C) 2025-2026 INHAUS CORP

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// Actually, since we haven't run flutterfire configure, this import will fail.
// I will temporarily verify without firebase init or handle it gracefully.
// For the purpose of this first run, I'll comment out Firebase init to get the UI running first.

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const ProviderScope(child: InhausBrainApp()));
}

class InhausBrainApp extends ConsumerWidget {
  const InhausBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Inhaus Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Using our custom premium dark theme
      routerConfig: router,
    );
  }
}
