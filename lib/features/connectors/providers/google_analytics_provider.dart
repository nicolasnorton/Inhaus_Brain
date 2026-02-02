import '../../../core/interfaces/integration_connector.dart';
import '../models/connected_account_model.dart';

class GoogleAnalyticsProvider implements AnalyticsConnector {
  @override
  AdPlatform get platform => AdPlatform.googleAnalytics;

  @override
  Future<Map<String, dynamic>> getCustomReport(
    ConnectedAccount account,
    List<String> dimensions,
    List<String> metrics,
    DateTime start,
    DateTime end,
  ) async {
    // START MOCK
    await Future.delayed(const Duration(seconds: 1));
    return {
      'kind': 'analyticsData#runReport',
      'rowCount': 30, // Days
      'rows': List.generate(7, (index) {
        return {
          'dimensionValues': [{'value': start.add(Duration(days: index)).toIso8601String().split('T')[0]}],
          'metricValues': [
            {'value': (1000 + (index * 50)).toString()}, // activeUsers
            {'value': (5000 + (index * 200)).toString()}, // screenPageViews
            {'value': (20 + (index * 2)).toString()},     // conversions
          ]
        };
      }),
      'totals': [
        {'dimensionValues': [], 'metricValues': [{'value': '15000'}, {'value': '65000'}, {'value': '450'}]}
      ]
    };
  }

  @override
  Future<Map<String, dynamic>> getAccountInsights(ConnectedAccount account, DateTime start, DateTime end) async {
    return {
      'totalUsers': 15000,
      'bounceRate': 0.45,
      'avgSessionDuration': 120,
    };
  }

  @override
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account) async {
    return account;
  }
}
