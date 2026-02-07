class ServiceProfitability {
  final String serviceId;
  final double revenue; // Actual or projected
  final double costs; // Delivery costs
  final double profit; // revenue - costs
  final double margin; // (profit / revenue) * 100
  final double targetMargin;
  final bool meetsTarget; // margin >= targetMargin

  ServiceProfitability({
    required this.serviceId,
    required this.revenue,
    required this.costs,
    required this.profit,
    required this.margin,
    required this.targetMargin,
    required this.meetsTarget,
  });

  factory ServiceProfitability.calculate({
    required String serviceId,
    required double revenue,
    required double costs,
    required double targetMargin,
  }) {
    final profit = revenue - costs;
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    return ServiceProfitability(
      serviceId: serviceId,
      revenue: revenue,
      costs: costs,
      profit: profit,
      margin: margin,
      targetMargin: targetMargin,
      meetsTarget: margin >= targetMargin,
    );
  }
}
