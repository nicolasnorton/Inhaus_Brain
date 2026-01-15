import 'ucp_types.dart';


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
    required super.id,
    super.name = 'Checkout',
    super.version = '1.0.0',
    this.supportedCurrencies = const [],
    this.allowsGuestCheckout = false,
    super.supportedExtensions,
  });
}

class IdentityLinkingCapability extends UCPCapability {
  final List<String> supportedProviders;

  IdentityLinkingCapability({
    required super.id,
    super.name = 'IdentityLinking',
    super.version = '1.0.0',
    this.supportedProviders = const [],
  });
}

class OrderCapability extends UCPCapability {
  final bool supportsOrderTracking;
  final bool supportsReturns;

  OrderCapability({
    required super.id,
    super.name = 'Order',
    super.version = '1.0.0',
    this.supportsOrderTracking = true,
    this.supportsReturns = false,
  });
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
    required super.id, 
    this.requiresMandate = true,
    this.supportedMandateVersions = const ['1.0'],
  }) : super(type: UCPExtensionType.ap2Mandates);
}

class BuyerConsentExtension extends UCPExtension {
  final String consentUrl;

  BuyerConsentExtension({required super.id, required this.consentUrl})
      : super(type: UCPExtensionType.buyerConsent);
}

class DiscountsExtension extends UCPExtension {
  final bool stackingAllowed;

  DiscountsExtension({required super.id, this.stackingAllowed = false})
      : super(type: UCPExtensionType.discounts);
}

class FulfillmentExtension extends UCPExtension {
  final List<String> supportedMethods; // ["shipping", "pickup"]

  FulfillmentExtension({required super.id, required this.supportedMethods})
      : super(type: UCPExtensionType.fulfillment);
}
