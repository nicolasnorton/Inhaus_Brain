import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';

Widget buildGoogleSignInButton({
  required BuildContext context,
  required Future<void> Function() onPressed,
  required bool isLoading,
}) {
  return SizedBox(
    width: 300,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(FontAwesomeIcons.google, size: 18, color: Colors.white),
      label: Text(
        AppLocalizations.of(context)!.signInLabel + " with Google", 
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );
}
