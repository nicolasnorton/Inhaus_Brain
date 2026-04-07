/// BudgetDashboardWidget — Real-time token usage HUD for the BudgetGovernor.
///
/// Displays a compact floating pill showing daily token consumption,
/// estimated cost, and active model tier. Changes color based on usage:
/// - Green (< 50%): Healthy
/// - Amber (50-80%): Moderate
/// - Red (> 80%): Critical / potentially downgraded model
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/budget_governor.dart';

class BudgetDashboardWidget extends ConsumerStatefulWidget {
  const BudgetDashboardWidget({super.key});

  @override
  ConsumerState<BudgetDashboardWidget> createState() => _BudgetDashboardWidgetState();
}

class _BudgetDashboardWidgetState extends ConsumerState<BudgetDashboardWidget>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _statusColor(double usage) {
    if (usage > 0.8) return const Color(0xFFEF4444); // Red
    if (usage > 0.5) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Green
  }

  IconData _statusIcon(double usage) {
    if (usage > 0.8) return Icons.warning_amber_rounded;
    if (usage > 0.5) return Icons.speed_rounded;
    return Icons.check_circle_outline_rounded;
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '$tokens';
  }

  @override
  Widget build(BuildContext context) {
    final governor = ref.watch(budgetGovernorProvider);
    final status = governor.getStatus();
    final summary = governor.getSessionSummary();
    final usage = status.usagePercent.clamp(0.0, 1.0);
    final color = _statusColor(usage);

    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        _expanded ? _animController.forward() : _animController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: _expanded ? 16.0 : 12.0,
          vertical: _expanded ? 12.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F16).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(_expanded ? 16.0 : 24.0),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Compact Pill Header ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(usage), color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatTokens(status.tokensUsedToday),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  ' / ${_formatTokens(status.dailyLimit)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                // Mini progress bar
                SizedBox(
                  width: 40,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: usage,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),

            // ── Expanded Detail Panel ──
            SizeTransition(
              sizeFactor: _fadeAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Color(0xFF2A2A3A), height: 1),
                      const SizedBox(height: 10),

                      // Cost row
                      _detailRow(
                        'Est. Cost Today',
                        '\$${status.costToday.toStringAsFixed(4)}',
                        Icons.attach_money_rounded,
                      ),
                      const SizedBox(height: 6),

                      // Model recommendation
                      _detailRow(
                        'Active Model Tier',
                        status.modelTierRecommendation.toUpperCase(),
                        Icons.memory_rounded,
                        valueColor: status.isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 6),

                      // Requests count
                      _detailRow(
                        'Requests',
                        '${summary['requestCount'] ?? 0}',
                        Icons.sync_rounded,
                      ),
                      const SizedBox(height: 6),

                      // Total session tokens
                      _detailRow(
                        'Session Total',
                        _formatTokens(summary['totalTokens'] as int? ?? 0),
                        Icons.data_usage_rounded,
                      ),

                      // Budget exceeded warning
                      if (status.isExceeded) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Budget exceeded — auto-downgraded to Flash Lite',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
