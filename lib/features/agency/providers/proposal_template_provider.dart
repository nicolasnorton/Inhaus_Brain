import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_template.dart';

class ProposalTemplateNotifier extends StateNotifier<List<ProposalTemplate>> {
  ProposalTemplateNotifier() : super(_getDefaultTemplates());

  void addTemplate(ProposalTemplate template) {
    state = [...state, template];
  }

  void updateTemplate(ProposalTemplate template) {
    state = [
      for (final t in state)
        if (t.id == template.id) template else t
    ];
  }

  void deleteTemplate(String id) {
    state = state.where((t) => t.id != id && !t.isDefault).toList();
  }

  ProposalTemplate? getTemplate(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  ProposalTemplate getDefaultTemplate() {
    return state.firstWhere((t) => t.isDefault, orElse: () => state.first);
  }

  static List<ProposalTemplate> _getDefaultTemplates() {
    return [
      // BRIAN Template (Default - Premium Gold/Dark)
      ProposalTemplate(
        id: 'brian-onepager',
        name: 'Brian One-Pager',
        description: 'Premium dark template with gold accents - perfect for executive summaries',
        type: ProposalTemplateType.onePager,
        style: ProposalTemplateStyle.brian,
        isDefault: true,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        config: TemplateConfig(
          colors: ColorScheme(
            background: '0xFF0F0F12',
            surface: '0xFF16161A',
            accent: '0xFFE5B15D',
            textPrimary: '0xFFFFFFFF',
            textSecondary: '0xFF94A3B8',
          ),
          typography: TypographyConfig(
            headingFont: 'Helvetica',
            bodyFont: 'Helvetica',
            headingSize: 32,
            bodySize: 14,
            letterSpacing: 1.2,
          ),
          layout: LayoutConfig(
            marginTop: 50,
            marginBottom: 40,
            marginLeft: 40,
            marginRight: 40,
            sectionSpacing: 20,
            showClientLogo: true,
            showAgencyLogo: true,
            headerAlignment: 'spaceBetween',
            showDividers: true,
          ),
          branding: BrandingConfig(
            agencyName: 'INHAUS',
            agencyTagline: 'BRAIN - CORE SYSTEMS',
            contactEmail: 'info@inhauscorp.com',
            contactPhone: '(+593) 98 656 6084',
            website: 'inhauscorp.com',
            footerText: 'APROBADO POR DIEGO ESPÍN',
          ),
        ),
      ),
      
      // BRIAN Multi-Page Template
      ProposalTemplate(
        id: 'brian-multipage',
        name: 'Brian Multi-Page',
        description: 'Premium dark template for comprehensive proposals',
        type: ProposalTemplateType.multiPage,
        style: ProposalTemplateStyle.brian,
        isDefault: false,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        config: TemplateConfig(
          colors: ColorScheme(
            background: '0xFF0F0F12',
            surface: '0xFF16161A',
            accent: '0xFFE5B15D',
            textPrimary: '0xFFFFFFFF',
            textSecondary: '0xFF94A3B8',
          ),
          typography: TypographyConfig(
            headingFont: 'Helvetica',
            bodyFont: 'Helvetica',
            headingSize: 24,
            bodySize: 12,
            letterSpacing: 1.0,
          ),
          layout: LayoutConfig(
            marginTop: 40,
            marginBottom: 40,
            marginLeft: 40,
            marginRight: 40,
            sectionSpacing: 30,
            showClientLogo: true,
            showAgencyLogo: true,
            headerAlignment: 'spaceBetween',
            showDividers: true,
          ),
          branding: BrandingConfig(
            agencyName: 'INHAUS',
            agencyTagline: 'BRAIN - CORE SYSTEMS',
            contactEmail: 'info@inhauscorp.com',
            contactPhone: '(+593) 98 656 6084',
            website: 'inhauscorp.com',
            footerText: 'APROBADO POR DIEGO ESPÍN',
          ),
        ),
      ),

      // Classic Template (Original Pink/Purple)
      ProposalTemplate(
        id: 'classic-onepager',
        name: 'Classic One-Pager',
        description: 'Original Inhaus template with pink accents',
        type: ProposalTemplateType.onePager,
        style: ProposalTemplateStyle.classic,
        isDefault: false,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        config: TemplateConfig(
          colors: ColorScheme(
            background: '0xFF1E1B2E',
            surface: '0xFF252238',
            accent: '0xFFD6335C',
            textPrimary: '0xFFFFFFFF',
            textSecondary: '0xFFAAAAAA',
          ),
          typography: TypographyConfig(
            headingFont: 'Helvetica',
            bodyFont: 'Helvetica',
            headingSize: 32,
            bodySize: 14,
            letterSpacing: 1.0,
          ),
          layout: LayoutConfig(
            marginTop: 40,
            marginBottom: 40,
            marginLeft: 40,
            marginRight: 40,
            sectionSpacing: 20,
            showClientLogo: true,
            showAgencyLogo: true,
            headerAlignment: 'spaceBetween',
            showDividers: false,
          ),
          branding: BrandingConfig(
            agencyName: 'INHAUS',
            agencyTagline: 'ESTUDIO CREATIVO',
            contactEmail: 'info@inhauscorp.com',
            contactPhone: '(+593) 98 656 6084',
            website: 'inhauscorp.com',
            footerText: 'APROBADO POR DIEGO ESPÍN',
          ),
        ),
      ),

      // Minimal Template
      ProposalTemplate(
        id: 'minimal-onepager',
        name: 'Minimal One-Pager',
        description: 'Clean, minimal template for straightforward proposals',
        type: ProposalTemplateType.onePager,
        style: ProposalTemplateStyle.minimal,
        isDefault: false,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        config: TemplateConfig(
          colors: ColorScheme(
            background: '0xFFFFFFFF',
            surface: '0xFFF5F5F5',
            accent: '0xFF2563EB',
            textPrimary: '0xFF1F2937',
            textSecondary: '0xFF6B7280',
          ),
          typography: TypographyConfig(
            headingFont: 'Helvetica',
            bodyFont: 'Helvetica',
            headingSize: 28,
            bodySize: 12,
            letterSpacing: 0.5,
          ),
          layout: LayoutConfig(
            marginTop: 60,
            marginBottom: 60,
            marginLeft: 50,
            marginRight: 50,
            sectionSpacing: 25,
            showClientLogo: true,
            showAgencyLogo: true,
            headerAlignment: 'left',
            showDividers: true,
          ),
          branding: BrandingConfig(
            agencyName: 'INHAUS',
            agencyTagline: 'Digital Solutions',
            contactEmail: 'info@inhauscorp.com',
            contactPhone: '(+593) 98 656 6084',
            website: 'inhauscorp.com',
            footerText: '',
          ),
        ),
      ),
    ];
  }
}

final proposalTemplatesProvider = StateNotifierProvider<ProposalTemplateNotifier, List<ProposalTemplate>>((ref) {
  return ProposalTemplateNotifier();
});

// Selected Template Provider
final selectedTemplateProvider = StateProvider<String>((ref) {
  return 'brian-onepager'; // Default to Brian template
});

// Get the currently selected template
final currentTemplateProvider = Provider<ProposalTemplate>((ref) {
  final templateId = ref.watch(selectedTemplateProvider);
  final templates = ref.watch(proposalTemplatesProvider);
  return templates.firstWhere(
    (t) => t.id == templateId,
    orElse: () => templates.first,
  );
});
