import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/proposal_model.dart';
import '../../agency/providers/service_catalog_riverpod_provider.dart';

class QuotePreviewModal extends ConsumerWidget {
  final Proposal proposal;

  const QuotePreviewModal({super.key, required this.proposal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(serviceCatalogProvider);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("INHAUS ESTUDIO CREATIVO", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(proposal.clientName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(proposal.title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 48, color: Colors.white24),
            
            // Body
            Expanded(
              child: catalogAsync.when(
                data: (catalog) {
                  final selectedServices = proposal.serviceIds.map((id) {
                    try {
                      return catalog!.services.firstWhere((s) => s.id == id);
                    } catch (_) {
                      return null;
                    }
                  }).whereType().toList();

                  if (selectedServices.isEmpty) {
                     return const Center(child: Text("No hay servicios seleccionados.", style: TextStyle(color: Colors.white54)));
                  }

                  double subtotal = selectedServices.fold(0, (sum, s) => sum + s.basePrice);
                  double discountAmnt = subtotal * (proposal.discount / 100);
                  double baseAmnt = subtotal - discountAmnt;
                  double ivaAmnt = proposal.applyIva ? baseAmnt * 0.15 : 0;
                  double total = baseAmnt + ivaAmnt;

                  return ListView(
                    children: [
                      const Text("DETALLE DE INVERSIÓN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Line Items Table
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: selectedServices.map((service) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.white12)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(service.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text("\$${service.basePrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Pricing Breakdown
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Subtotal:", style: TextStyle(color: Colors.white70)),
                                  Text("\$${subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              if (proposal.discount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Descuento (${proposal.discount.toStringAsFixed(0)}%):", style: const TextStyle(color: Colors.redAccent)),
                                    Text("-\$${discountAmnt.toStringAsFixed(2)}", style: const TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ],
                              if (proposal.applyIva) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("IVA (15%):", style: TextStyle(color: Colors.white70)),
                                    Text("\$${ivaAmnt.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ],
                              const Divider(height: 32, color: Colors.white24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TOTAL:", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error loading catalog: $e", style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
