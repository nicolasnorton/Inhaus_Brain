import 'dart:async';

class ExternalIntegrationService {
  final String providerName;

  ExternalIntegrationService(this.providerName);

  Future<bool> connect() async {
    // Simulate OAuth/API connection
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<List<String>> fetchData() async {
    // Simulate fetching data from external service
    await Future.delayed(const Duration(seconds: 1));
    return ['Entry 1 from $providerName', 'Entry 2 from $providerName'];
  }
}

class GmailService extends ExternalIntegrationService {
  GmailService() : super('Gmail');
  
  Future<void> sendEmail(String to, String subject, String body) async {
    // Logic to send email
  }
}

class SlackService extends ExternalIntegrationService {
  SlackService() : super('Slack');

  Future<void> sendMessage(String channel, String message) async {
    // Logic to send slack message
  }
}

class NotionService extends ExternalIntegrationService {
  NotionService() : super('Notion');

  Future<void> createPage(String databaseId, Map<String, dynamic> properties) async {
    // Logic to create notion page
  }
}

class GoHighLevelService extends ExternalIntegrationService {
  GoHighLevelService() : super('GoHighLevel');

  Future<void> createContact(Map<String, dynamic> contactData) async {
    // Logic to create GHL contact
  }
}
