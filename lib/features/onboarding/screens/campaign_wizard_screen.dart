
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
      backgroundColor: Colors.black, // Pure Black
      appBar: AppBar(
        title: const Text(
          'SETUP ASSISTANT', 
          style: TextStyle(
            color: Colors.white, 
            letterSpacing: 2.0, 
            fontSize: 14, 
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Minimalist Progress Indicator
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: Colors.white12,
              color: Colors.white, // White progress
              minHeight: 2,
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: _buildCurrentStep(),
              ),
            ),
            
            // Navigation with Sharp Buttons
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12, width: 1))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: const Text('BACK', style: TextStyle(letterSpacing: 1.5, fontSize: 12)),
                    )
                  else
                    const SizedBox.shrink(),
                    
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleNext,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        _step == 2 ? 'INITIALIZE' : 'NEXT', 
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)
                      ),
                    ),
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
          "BRAND IDENTITY",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2.0),
        ),
        const SizedBox(height: 16),
        const Text(
          "Who is the Client?",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          "Enter brand details to calibrate the AI model.",
          style: TextStyle(fontSize: 14, color: Colors.white38),
        ),
        const SizedBox(height: 48),
        
        TextField(
          controller: _brandController,
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'BRAND NAME',
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 48),
        
        const Text("INDUSTRY SECTOR", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Technology', 'Retail', 'Finance', 'Healthcare', 'Food & Bev'].map((ind) {
            final isSelected = _industry == ind;
            return ChoiceChip(
              label: Text(ind.toUpperCase()),
              selected: isSelected,
              onSelected: (val) => setState(() => _industry = ind),
              selectedColor: Colors.white,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              shape: isSelected 
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)) // Sharp
                : RoundedRectangleBorder(side: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(0)),
              checkmarkColor: Colors.black,
            );
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
          "TONE PARAMETERS",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2.0),
        ),
        const SizedBox(height: 16),
        const Text(
          "Select Voice Profile",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
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
      splashColor: Colors.white24,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white24, width: 1),
          borderRadius: BorderRadius.zero, // Sharp corners
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: isSelected ? Colors.black : Colors.white, size: 24),
            const SizedBox(height: 12),
            Text(
              tone.toUpperCase(), 
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.5,
              )
            ),
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
          "MARKET CONTEXT",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2.0),
        ),
        const SizedBox(height: 16),
        const Text(
          "Regional Calibration",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white),
        ),
        const SizedBox(height: 32),
        
        _buildRegionTile('Guayaquil, Ecuador', 'Coastal, dynamic, commerce-driven'),
        const SizedBox(height: 16),
        _buildRegionTile('Quito, Ecuador', 'Andean, formal, unexpected weather'),
        const SizedBox(height: 16),
        _buildRegionTile('LatAm General', 'Neutral Spanish, broad appeal'),
      ],
    );
  }

  Widget _buildRegionTile(String title, String subtitle) {
    final isSelected = _region == title;
    return InkWell(
      onTap: () => setState(() => _region = title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isSelected ? Colors.black54 : Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (mounted) {
         Navigator.of(context).pop(); 
      }
    }
  }
}
