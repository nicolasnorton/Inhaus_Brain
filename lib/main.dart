// Inhaus_Brain
// FORCE_REBUILD_V3
// Copyright (C) 2025-2026 INHAUS CORP

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/settings/providers/user_provider.dart';
import 'core/services/hotkey_service.dart';
import 'core/commands/widgets/command_palette.dart';
import 'core/widgets/hotkey_cheat_sheet.dart';
import 'package:flutter/services.dart';
import 'core/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 INHAUS BRAIN v1.1.1-DEMO-READY STARTED');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded. $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      // Use IPv4 loopback to align with browser origin and avoid IPv6 issues
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5005);
      print('🔥 Using Firestore Emulator on 127.0.0.1:8080');
      print('🔥 Using Functions Emulator on 127.0.0.1:5005');
    } catch (e) {
      print('⚠️ Failed to connect to Firebase Emulators: $e');
    }
  }
  
  // App Check Activation
  // Site Key: 6LeGhFcsAAAAAGbtF7S_rnocz9BiauHPtQWBKZcy
  try {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6LeGhFcsAAAAAGbtF7S_rnocz9BiauHPtQWBKZcy'),
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    
    // Attempt to retrieve and log the token to verify the handshake
    final tokenResult = await FirebaseAppCheck.instance.getToken(true);
    debugPrint('✅ App Check activated successfully.');
    debugPrint('📝 App Check token: $tokenResult');
    // debugPrint('Token expires: ${DateTime.fromMillisecondsSinceEpoch(tokenResult?.expireTimeMillis ?? 0)}'); // API v0.3.0+ returns String?
    debugPrint('Is debug mode: ${kDebugMode}'); // Checking if kDebugMode is actually true
  } catch (e, stack) {
    debugPrint('❌ App Check activation failed: $e');
    debugPrint('Stack trace: $stack');
    // Continue without App Check in dev if it fails, to prevent crashing
  }

  runApp(const ProviderScope(child: InhausBrainApp()));
}

class InhausBrainApp extends ConsumerWidget {
  const InhausBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final hotkeyService = ref.watch(hotkeyProvider);

    // Register global hotkeys
    hotkeyService.register(
      const Hotkey(
        key: LogicalKeyboardKey.keyK,
        meta: true, // Use meta for Cmd on Mac, Ctrl on others (simplified for now)
        label: 'Command Palette',
        description: 'Open the universal search and command palette',
      ),
      (context) {
        showDialog(
          context: context,
          builder: (context) => const CommandPalette(),
        );
      },
    );

    hotkeyService.register(
      const Hotkey(
        key: LogicalKeyboardKey.slash,
        meta: true,
        label: 'Keyboard Shortcuts',
        description: 'Show the keyboard shortcuts cheat sheet',
      ),
      (context) {
        showDialog(
          context: context,
          builder: (context) => const HotkeyCheatSheet(),
        );
      },
    );

    return GlobalHotkeyListener(
      child: MaterialApp.router(
        title: 'Inhaus Brain',
        debugShowCheckedModeBanner: false,
        theme: preferences.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        routerConfig: router,
        scaffoldMessengerKey: scaffoldMessengerKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('es'), // Spanish
        ],
        locale: Locale(preferences.language.code),
        builder: (context, child) {
          return FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: child!,
          );
        },
      ),
    );
  }
}
