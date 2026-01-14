import 'capability_model.dart';

abstract class UCPParticipant {
  final String id;
  final String name;

  UCPParticipant({required this.id, required this.name});
}

class PlatformAgent extends UCPParticipant {
  final String version;

  PlatformAgent({required String id, required String name, required this.version})
      : super(id: id, name: name);
}

class Business extends UCPParticipant {
  final List<UCPCapability> capabilities;
  final String merchantId;

  Business({
    required String id,
    required String name,
    required this.merchantId,
    this.capabilities = const [],
  }) : super(id: id, name: name);
}

class CredentialProvider extends UCPParticipant {
  final List<String> supportedMethods; // e.g., ["visa", "mastercard", "apple_pay"]

  CredentialProvider({
    required String id,
    required String name,
    this.supportedMethods = const [],
  }) : super(id: id, name: name);
}

class PaymentServiceProvider extends UCPParticipant {
  final String gatewayId;

  PaymentServiceProvider({
    required String id,
    required String name,
    required this.gatewayId,
  }) : super(id: id, name: name);
}
