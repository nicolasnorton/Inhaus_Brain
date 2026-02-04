import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/clients/providers/client_integrations_provider.dart';

class ClientIntegrationsScreen extends ConsumerWidget {
  final String clientId;

  const ClientIntegrationsScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the state for THIS filtered client
    final allIntegrations = ref.watch(clientIntegrationsProvider);
    final integrations = allIntegrations[clientId] ?? ClientIntegrationState();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Productivity'),
          _IntegrationCard(
            title: 'Gmail',
            icon: FontAwesomeIcons.google,
            isConnected: integrations.isGmailConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Gmail', val),
          ),
          _IntegrationCard(
            title: 'Slack',
            icon: FontAwesomeIcons.slack,
            isConnected: integrations.isSlackConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Slack', val),
          ),
          _IntegrationCard(
            title: 'Notion',
            icon: FontAwesomeIcons.notion,
            isConnected: integrations.isNotionConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Notion', val),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Advertising'),
          _IntegrationCard(
            title: 'Google Ads',
            icon: FontAwesomeIcons.google,
            isConnected: integrations.isGoogleAdsConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Google Ads', val),
          ),
          _IntegrationCard(
            title: 'Meta Ads',
            icon: FontAwesomeIcons.meta,
            isConnected: integrations.isMetaAdsConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Meta Ads', val),
          ),
          _IntegrationCard(
            title: 'TikTok Ads',
            icon: FontAwesomeIcons.tiktok,
            isConnected: integrations.isTikTokAdsConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'TikTok Ads', val),
          ),
          _IntegrationCard(
            title: 'LinkedIn Ads',
            icon: FontAwesomeIcons.linkedin,
            isConnected: integrations.isLinkedInAdsConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'LinkedIn Ads', val),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Analytics'),
          _IntegrationCard(
            title: 'Google Analytics 4',
            icon: FontAwesomeIcons.chartLine,
            isConnected: integrations.isGA4Connected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Google Analytics 4', val),
          ),
          _IntegrationCard(
            title: 'Search Console',
            icon: FontAwesomeIcons.magnifyingGlassChart,
            isConnected: integrations.isSearchConsoleConnected,
            onToggle: (val) => ref.read(clientIntegrationsProvider.notifier).handleToggle(clientId, 'Search Console', val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isConnected;
  final ValueChanged<bool> onToggle;

  const _IntegrationCard({
    required this.title,
    required this.icon,
    required this.isConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? Colors.green.withOpacity(0.5) : Colors.transparent),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Text('Connected', style: TextStyle(color: Colors.green, fontSize: 12)),
            ),
          Switch(
            value: isConnected,
            onChanged: onToggle,
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
