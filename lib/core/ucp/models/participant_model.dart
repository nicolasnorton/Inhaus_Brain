import 'capability_model.dart';

abstract class UCPParticipant {
  final String id;
  final String name;

  UCPParticipant({required this.id, required this.name});
}

class PlatformAgent extends UCPParticipant {
  final String version;

  PlatformAgent({required super.id, required super.name, required this.version});
}

class Business extends UCPParticipant {
  final List<UCPCapability> capabilities;
  final String merchantId;

  Business({
    required super.id,
    required super.name,
    required this.merchantId,
    this.capabilities = const [],
  });
}

class CredentialProvider extends UCPParticipant {
  final List<String> supportedMethods; // e.g., ["visa", "mastercard", "apple_pay"]

  CredentialProvider({
    required super.id,
    required super.name,
    this.supportedMethods = const [],
  });
}

class PaymentServiceProvider extends UCPParticipant {
  final String gatewayId;

  PaymentServiceProvider({
    required super.id,
    required super.name,
    required this.gatewayId,
  });
}
