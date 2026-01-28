
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/onboarding/providers/onboarding_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';

class CampaignWizardScreen extends ConsumerStatefulWidget {
  const CampaignWizardScreen({super.key});

  @override
  ConsumerState<CampaignWizardScreen> createState() => _CampaignWizardScreenState();
}

class _CampaignWizardScreenState extends ConsumerState<CampaignWizardScreen> {
  int _step = 0;
  
  // Step 1: Brand Info
  final _brandController = TextEditingController();
  String _industry = 'Technology';
  
  // Step 2: Tone
  String _tone = 'Professional';
  
  // Step 3: Regional
  String _region = 'Guayaquil, Ecuador';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Setup Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: Colors.white10,
              color: Colors.blueAccent,
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildCurrentStep(),
              ),
            ),
            
            // Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back', style: TextStyle(color: Colors.white54)),
                    )
                  else
                    const SizedBox.shrink(),
                    
                  ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(_step == 2 ? 'Launch Brain' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return Container();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Let's start with your Brand.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "Brian needs to know who he is working for.",
          style: TextStyle(fontSize: 16, color: Colors.white54),
        ),
        const SizedBox(height: 32),
        
        TextField(
          controller: _brandController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Brand Name',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        
        const Text("Industry", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Technology', 'Retail', 'Finance', 'Healthcare', 'Food & Bev'].map((ind) {
            final isSelected = _industry == ind;
            return ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(ind),
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _industry = ind),
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ).animate().fadeIn().scale();
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Define your Voice.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "How should Brian sound when generating content?",
          style: TextStyle(fontSize: 16, color: Colors.white54),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildToneCard('Professional', FontAwesomeIcons.userTie),
              _buildToneCard('Friendly', FontAwesomeIcons.faceSmile),
              _buildToneCard('Bold', FontAwesomeIcons.bullhorn),
              _buildToneCard('Luxurious', FontAwesomeIcons.gem),
              _buildToneCard('Witty', FontAwesomeIcons.masksTheater),
              _buildToneCard('Empathetic', FontAwesomeIcons.handHoldingHeart),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildToneCard(String tone, IconData icon) {
    final isSelected = _tone == tone;
    return InkWell(
      onTap: () => setState(() => _tone = tone),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: isSelected ? Colors.blueAccent : Colors.white54, size: 28),
            const SizedBox(height: 12),
            Text(tone, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Regional Context.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "We tune the AI for local market nuances (slang, holidays, trends).",
          style: TextStyle(fontSize: 16, color: Colors.white54),
        ),
        const SizedBox(height: 32),
        
        ListTile(
          title: const Text('Guayaquil, Ecuador', style: TextStyle(color: Colors.white)),
          subtitle: const Text('focus: Coastal, dynamic, commerce-driven', style: TextStyle(color: Colors.white54)),
          leading: const Icon(Icons.location_on, color: Colors.redAccent),
          tileColor: _region == 'Guayaquil, Ecuador' ? Colors.white10 : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => setState(() => _region = 'Guayaquil, Ecuador'),
          trailing: _region == 'Guayaquil, Ecuador' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Quito, Ecuador', style: TextStyle(color: Colors.white)),
          subtitle: const Text('focus: Andean, formal, unexpected weather', style: TextStyle(color: Colors.white54)),
          leading: const Icon(Icons.location_on, color: Colors.blueAccent),
          tileColor: _region == 'Quito, Ecuador' ? Colors.white10 : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => setState(() => _region = 'Quito, Ecuador'),
          trailing: _region == 'Quito, Ecuador' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
        ),
         const SizedBox(height: 8),
        ListTile(
          title: const Text('LatAm General', style: TextStyle(color: Colors.white)),
          subtitle: const Text('focus: Neutral Spanish, broad appeal', style: TextStyle(color: Colors.white54)),
          leading: const Icon(Icons.public, color: Colors.greenAccent),
          tileColor: _region == 'LatAm General' ? Colors.white10 : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => setState(() => _region = 'LatAm General'),
          trailing: _region == 'LatAm General' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      // Create Campaign via Provider? Or just complete onboarding.
      // For this wizard, we just simulating setting up the "System Prompt" context.
      // In a real app we'd save this to `BrandProfileService`.
      
      // Complete Onboarding
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (mounted) {
         Navigator.of(context).pop(); // Go to Main App (since main listener will rebuild)
      }
    }
  }
}
