
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/onboarding/providers/onboarding_provider.dart';
import 'package:inhaus_brain/features/onboarding/screens/campaign_wizard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Central Brain Icon
              // Central Brain Icon
              Image.asset(
                'assets/images/inhaus_brain_logo.png',
                width: 300, // Increased for full logo visibility
                fit: BoxFit.contain,
                color: Colors.white,
              ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
              
              const SizedBox(height: 32),
              
              // App Name
               const Text(
                "INHAUS BRAIN",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 12),
              
              const Text(
                "v1.0.1",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white24,
                  letterSpacing: 1.0,
                ),
              ),

              const Spacer(),
              
              // Get Started Button - Minimalist White
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                     Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => const CampaignWizardScreen()),
                     );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "INITIALIZE SYSTEMS", 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    )
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Skip
              TextButton(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).completeOnboarding();
                },
                child: const Text("SKIP SETUP", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
