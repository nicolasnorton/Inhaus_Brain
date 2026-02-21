import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/package.dart';
import '../models/constants.dart';
import '../services/proposals_repository.dart';
import '../services/agency_service_adapter.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';

/// Packages manager (Productos) ported from `packages-view.tsx`.
///
/// Features:
/// - Group tabs (Estudio, Media, Producción, Nuhaus)
/// - Category-grouped card grid
/// - Expandable section previews
/// - Soft-delete with master-key confirmation dialog
/// - Deleted packages view with restore
class PackagesManagerView extends ConsumerStatefulWidget {
  final ProposalsRepository service;
  final void Function(Package pkg)? onAddToQuote;
  final void Function(Package pkg)? onEditPackage;

  const PackagesManagerView({
    super.key,
    required this.service,
    this.onAddToQuote,
    this.onEditPackage,
  });

  @override
  ConsumerState<PackagesManagerView> createState() => _PackagesManagerViewState();
}

class _PackagesManagerViewState extends ConsumerState<PackagesManagerView> {
  String _activeGroup = 'Estudio';
  final Set<String> _expandedCards = {};

  static const _accent = Color(0xFFE8006A);
  static const _bg = Color(0xFF111111);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2A2A2A);

  List<Package> _getFiltered(List<Package> allPackages) =>
      allPackages.where((p) => p.packageGroup == _activeGroup).toList();

  List<String> _getCategories(List<Package> filtered) =>
      filtered.map((p) => p.category).toSet().toList();

  Map<String, int> _getGroupCounts(List<Package> allPackages) {
    final counts = <String, int>{};
    for (final g in packageGroups) {
      counts[g] = allPackages.where((p) => p.packageGroup == g).length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        title: const Text('PRODUCTOS',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 3)),
        actions: [
          // Removed "Eliminados" toggle as it's no longer applicable for global catalog
        ],
      ),
      body: servicesAsync.when(
        data: (services) {
          final allPackages = AgencyServiceAdapter.toPackages(services);
          return _buildMainList(allPackages);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _accent)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  // ---- Group tabs + card grid ----
  Widget _buildMainList(List<Package> allPackages) {
    final filtered = _getFiltered(allPackages);
    final categories = _getCategories(filtered);
    final groupCounts = _getGroupCounts(allPackages);

    return Column(
      children: [
        // Group tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: packageGroups.map((g) {
              final isActive = g == _activeGroup;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(g),
                    if ((groupCounts[g] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text('${groupCounts[g]}',
                            style: TextStyle(
                                fontSize: 10,
                                color: isActive ? Colors.white70 : Colors.white38)),
                      ),
                  ]),
                  selected: isActive,
                  selectedColor: _accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isActive ? Colors.white : Colors.white54),
                  onSelected: (_) => setState(() => _activeGroup = g),
                ),
              );
            }).toList(),
          ),
        ),
        // Content
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh, size: 40, color: Colors.white12),
                    const SizedBox(height: 8),
                    Text('No hay paquetes en $_activeGroup',
                        style: const TextStyle(fontSize: 14, color: Colors.white38)),
                  ]),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: categories.map((cat) {
                    final catPkgs = filtered.where((p) => p.category == cat).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(cat,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _accent,
                                  letterSpacing: 3)),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: catPkgs.map(_buildPackageCard).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(Package pkg) {
    final expanded = _expandedCards.contains(pkg.slug);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pkg.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(formatCurrency(pkg.price),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _accent)),
          if (pkg.billing.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: pkg.billing.toLowerCase().contains('mensual')
                    ? Colors.blue.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(pkg.billing,
                  style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: pkg.billing.toLowerCase().contains('mensual')
                          ? Colors.blueAccent
                          : Colors.greenAccent)),
            ),
          ],
          const SizedBox(height: 8),
          if (!expanded && pkg.sections.isNotEmpty)
            Text(
              pkg.sections[0].content.length > 100
                  ? '${pkg.sections[0].content.substring(0, 100)}...'
                  : pkg.sections[0].content,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (expanded)
            ...pkg.sections.map((sec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sec.title.isNotEmpty)
                        Text(sec.title,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _accent,
                                letterSpacing: 1)),
                      Text(sec.content,
                          style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                )),
          if (pkg.sections.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedCards.remove(pkg.slug);
                } else {
                  _expandedCards.add(pkg.slug);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 14, color: _accent),
                  Text(expanded ? 'Ver menos' : 'Ver más',
                      style: const TextStyle(fontSize: 11, color: _accent)),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onAddToQuote?.call(pkg),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Agregar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: BorderSide(color: _accent.withValues(alpha: 0.4))),
              ),
            ),
              const SizedBox(width: 4),
              /* Edit and Delete are disabled as catalog is centrally managed via Agency Services
            IconButton(
              icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
              onPressed: () => widget.onEditPackage?.call(pkg),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 14, color: Colors.redAccent),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            */
          ]),
        ],
      ),
    );
  }
}
