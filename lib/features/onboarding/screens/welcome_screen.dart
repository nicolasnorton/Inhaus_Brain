
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
      backgroundColor: Colors.black, // Sleek dark mode
      body: Stack(
        children: [
          // Background Gradient (Ecuadorian-inspired but subtle)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
          
          // Foreground Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blueAccent,
                    child: FaIcon(FontAwesomeIcons.brain, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  
                  // Welcome Text
                  const Text(
                    "Welcome to Inhaus Brain",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 16),
                  
                  const Text(
                    "Your AI-Powered Chief of Staff for\nHigh-Performance Marketing.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Get Started Button
                  SizedBox(
                    width: 200,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (_) => const CampaignWizardScreen()),
                         );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Get Started", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Skip for existing users (Dev only mostly)
                  TextButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).completeOnboarding();
                    },
                    child: const Text("Skip setup", style: TextStyle(color: Colors.white24)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
