class PsychedelicOrder {
  final String userId; // to link to a logged-in user, if necessary
  final bool isMushroomOrder; // true for mushrooms, false for truffles

  final String namePseudonym;
  final String email;
  final String quantity; // "3" or "4"

  // For mushrooms: might store donation preference
  // For truffles: might store payment accepted
  final bool donationOrPaymentSelected;

  // The user must confirm they’re 18+, etc.
  final bool declarationConfirmed;

  PsychedelicOrder({
    required this.userId,
    required this.isMushroomOrder,
    required this.namePseudonym,
    required this.email,
    required this.quantity,
    required this.donationOrPaymentSelected,
    required this.declarationConfirmed,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isMushroomOrder': isMushroomOrder,
      'namePseudonym': namePseudonym,
      'email': email,
      'quantity': quantity,
      'donationOrPaymentSelected': donationOrPaymentSelected,
      'declarationConfirmed': declarationConfirmed,
    };
  }

  // If reading back from Firestore
  factory PsychedelicOrder.fromMap(Map<String, dynamic> map) {
    return PsychedelicOrder(
      userId: map['userId'] ?? '',
      isMushroomOrder: map['isMushroomOrder'] ?? true,
      namePseudonym: map['namePseudonym'] ?? '',
      email: map['email'] ?? '',
      quantity: map['quantity'] ?? '3',
      donationOrPaymentSelected: map['donationOrPaymentSelected'] ?? false,
      declarationConfirmed: map['declarationConfirmed'] ?? false,
    );
  }
}
