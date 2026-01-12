// Inhaus_Brain
// Copyright (C) 2025-2026 INHAUS CORP

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// Actually, since we haven't run flutterfire configure, this import will fail.
// I will temporarily verify without firebase init or handle it gracefully.
// For the purpose of this first run, I'll comment out Firebase init to get the UI running first.

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/settings/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded. $e");
  }

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
    final preferences = ref.watch(userPreferencesProvider);

    return MaterialApp.router(
      title: 'Inhaus Brain',
      debugShowCheckedModeBanner: false,
      theme: preferences.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
