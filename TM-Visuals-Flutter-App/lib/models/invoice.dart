class Invoice {
  final String reference;
  final String dateCreated;

  const Invoice({required this.reference, required this.dateCreated});

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      reference: json['reference'] ?? '',
      dateCreated: json['date_created'] ?? '',
    );
  }
}