class PaymentMethod {
  final String id;
  final String displayName;
  final String description;
  final String? iconUrl;

  PaymentMethod({
    required this.id,
    required this.displayName,
    required this.description,
    this.iconUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      displayName: json['display_name'],
      description: json['description'],
      iconUrl: json['icon_url'],
    );
  }
}
