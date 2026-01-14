/// Core status for UCP transactions
enum UCPTransactionStatus {
  pending,
  authorized,
  captured,
  failed,
  cancelled,
  refunded,
}

/// The type of network action being performed
enum ServiceType {
  rest,
  mcp,
  a2a,
}

/// Verification levels for credentials
enum CredentialLevel {
  basic,
  verified,
  governmentId,
}

/// Currency codes supported by UCP (ISO 4217 subset involved in commerce)
enum CurrencyCode {
  usd,
  eur,
  gbp,
  jpy,
  aud,
  cad,
}

/// The protocol binding used for communication
enum UCPBinding {
  httpRest,
  mcp,
  a2a,
  ep,
}

/// Known standard extensions
enum UCPExtensionType {
  ap2Mandates,
  buyerConsent,
  discounts,
  fulfillment,
}
