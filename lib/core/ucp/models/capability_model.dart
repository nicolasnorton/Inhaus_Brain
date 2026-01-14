import 'ucp_types.dart';
import 'ap2_models.dart';


abstract class UCPCapability {
  final String id;
  final String name;
  final String version;
  final List<String> supportedExtensions;

  UCPCapability({
    required this.id,
    required this.name,
    required this.version,
    this.supportedExtensions = const [],
  });
}

class CheckoutCapability extends UCPCapability {
  final List<CurrencyCode> supportedCurrencies;
  final bool allowsGuestCheckout;

  CheckoutCapability({
    required String id,
    String name = 'Checkout',
    String version = '1.0.0',
    this.supportedCurrencies = const [],
    this.allowsGuestCheckout = false,
    List<String> supportedExtensions = const [],
  }) : super(id: id, name: name, version: version, supportedExtensions: supportedExtensions);
}

class IdentityLinkingCapability extends UCPCapability {
  final List<String> supportedProviders;

  IdentityLinkingCapability({
    required String id,
    String name = 'IdentityLinking',
    String version = '1.0.0',
    this.supportedProviders = const [],
  }) : super(id: id, name: name, version: version);
}

class OrderCapability extends UCPCapability {
  final bool supportsOrderTracking;
  final bool supportsReturns;

  OrderCapability({
    required String id,
    String name = 'Order',
    String version = '1.0.0',
    this.supportsOrderTracking = true,
    this.supportsReturns = false,
  }) : super(id: id, name: name, version: version);
}


abstract class UCPExtension {
  final String id;
  final UCPExtensionType type;

  UCPExtension({required this.id, required this.type});
}

class AP2MandatesExtension extends UCPExtension {
  final bool requiresMandate;
  final List<String> supportedMandateVersions;

  AP2MandatesExtension({
    required String id, 
    this.requiresMandate = true,
    this.supportedMandateVersions = const ['1.0'],
  }) : super(id: id, type: UCPExtensionType.ap2Mandates);
}

class BuyerConsentExtension extends UCPExtension {
  final String consentUrl;

  BuyerConsentExtension({required String id, required this.consentUrl})
      : super(id: id, type: UCPExtensionType.buyerConsent);
}

class DiscountsExtension extends UCPExtension {
  final bool stackingAllowed;

  DiscountsExtension({required String id, this.stackingAllowed = false})
      : super(id: id, type: UCPExtensionType.discounts);
}

class FulfillmentExtension extends UCPExtension {
  final List<String> supportedMethods; // ["shipping", "pickup"]

  FulfillmentExtension({required String id, required this.supportedMethods})
      : super(id: id, type: UCPExtensionType.fulfillment);
}
