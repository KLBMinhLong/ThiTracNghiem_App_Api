class TwoFaSetupResponse {
  final String sharedKey;
  final String authenticatorUri;
  final bool enabled;

  const TwoFaSetupResponse({
    required this.sharedKey,
    required this.authenticatorUri,
    required this.enabled,
  });

  factory TwoFaSetupResponse.fromJson(Map<String, dynamic> json) {
    return TwoFaSetupResponse(
      sharedKey: json['sharedKey'] as String? ?? '',
      authenticatorUri: json['authenticatorUri'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}
