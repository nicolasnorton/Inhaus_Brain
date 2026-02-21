import '../../agency/models/agency_service_model.dart';
import '../models/package.dart';
import '../models/section.dart';

/// Bridges the existing AgencyService catalog to the Package model
/// expected by the Cotizador views.
///
/// This ensures a single catalog — the AgencyService collection — is the
/// source of truth for both the Packages tab and the Cotizador editor.
class AgencyServiceAdapter {
  /// Convert an AgencyService to a Package (for display in Cotizador views).
  static Package toPackage(AgencyService service) {
    return Package(
      id: service.id,
      slug: service.id, // Use ID as slug since AgencyService has no slug
      name: service.name,
      category: service.metadata['category'] as String? ?? 'General',
      price: service.basePrice,
      billing: _mapFrequencyToBilling(service.frequency),
      sections: _buildSections(service),
      isCustom: false,
      packageGroup: service.metadata['category'] as String? ?? 'Estudio',
      createdAt: service.createdAt,
    );
  }

  /// Convert a Package back to an AgencyService (for write-back to catalog).
  static AgencyService toAgencyService(Package pkg, {AgencyService? existing}) {
    final now = DateTime.now();
    return AgencyService(
      id: pkg.id.isEmpty ? '' : pkg.id,
      name: pkg.name,
      description: pkg.sections.isNotEmpty ? pkg.sections.first.content : '',
      price: pkg.price.toStringAsFixed(2),
      basePrice: pkg.price,
      frequency: _mapBillingToFrequency(pkg.billing),
      billingCycle: _mapBillingToCycle(pkg.billing),
      details: pkg.sections.map((s) => s.content).toList(),
      metadata: {
        ...?existing?.metadata,
        'category': pkg.category,
        'packageGroup': pkg.packageGroup,
      },
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Convert a list of AgencyServices to Packages.
  static List<Package> toPackages(List<AgencyService> services) {
    return services.map(toPackage).toList();
  }

  // Build sections from AgencyService fields (description, deliverables, includes).
  static List<Section> _buildSections(AgencyService service) {
    final sections = <Section>[];

    if (service.description.isNotEmpty) {
      sections.add(Section(title: 'Descripción', content: service.description));
    }

    if (service.deliverables.isNotEmpty) {
      sections.add(Section(
        title: 'Entregables',
        content: service.deliverables.join('\n• '),
      ));
    }

    if (service.includes.isNotEmpty) {
      sections.add(Section(
        title: 'Incluye',
        content: service.includes.join('\n• '),
      ));
    }

    if (service.execution.isNotEmpty) {
      sections.add(Section(title: 'Ejecución', content: service.execution));
    }

    return sections;
  }

  static String _mapFrequencyToBilling(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'monthly':
        return 'Pago mensual';
      case 'bimonthly':
        return 'Cada dos meses';
      case 'quarterly':
        return 'Trimestral';
      case 'yearly':
        return 'Anual';
      case 'one-time':
      default:
        return 'Pago único';
    }
  }

  static String _mapBillingToFrequency(String billing) {
    switch (billing.toLowerCase()) {
      case 'pago mensual':
        return 'monthly';
      case 'cada dos meses':
        return 'bimonthly';
      case 'trimestral':
        return 'quarterly';
      case 'anual':
        return 'yearly';
      case 'pago único':
      default:
        return 'one-time';
    }
  }

  static BillingCycle _mapBillingToCycle(String billing) {
    switch (billing.toLowerCase()) {
      case 'pago mensual':
        return BillingCycle.monthly;
      case 'cada dos meses':
        return BillingCycle.bimonthly;
      case 'pago único':
      default:
        return BillingCycle.oneTime;
    }
  }
}
