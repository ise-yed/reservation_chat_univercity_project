class ZarinpalRequestResponse {
  final String transaction;
  final String zarinpalUrl;

  ZarinpalRequestResponse({
    required this.transaction,
    required this.zarinpalUrl,
  });

  factory ZarinpalRequestResponse.fromJson(Map<String, dynamic> json) {
    return ZarinpalRequestResponse(
      transaction: json['transaction'],
      zarinpalUrl: json['zarinpalUrl'],
    );
  }
}
