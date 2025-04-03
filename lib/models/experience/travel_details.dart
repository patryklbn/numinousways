// models/travel_details.dart
class TravelDetails {
  final String userId;

  final String name;
  final String surname;
  final String mobileNumber;

  final String methodOfArrival;
  final String arrivalFlightNumber;
  final String arrivalDate;
  final String arrivalTime;

  final String departureMethod;
  final String departureFlightNumber;
  final String departureDate;
  final String departureTime;

  final String passportNumber;
  final String passportIssuingDate;
  final String passportPlaceOfIssue;
  final String birthPlace;
  final String dob;
  final String nationality;

  final String additionalComment;

  TravelDetails({
    required this.userId,
    required this.name,
    required this.surname,
    required this.mobileNumber,
    required this.methodOfArrival,
    required this.arrivalFlightNumber,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.departureMethod,
    required this.departureFlightNumber,
    required this.departureDate,
    required this.departureTime,
    required this.passportNumber,
    required this.passportIssuingDate,
    required this.passportPlaceOfIssue,
    required this.birthPlace,
    required this.dob,
    required this.nationality,
    required this.additionalComment,
  });

  // Convert model to Map (to store in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'surname': surname,
      'mobileNumber': mobileNumber,
      'methodOfArrival': methodOfArrival,
      'arrivalFlightNumber': arrivalFlightNumber,
      'arrivalDate': arrivalDate,
      'arrivalTime': arrivalTime,
      'departureMethod': departureMethod,
      'departureFlightNumber': departureFlightNumber,
      'departureDate': departureDate,
      'departureTime': departureTime,
      'passportNumber': passportNumber,
      'passportIssuingDate': passportIssuingDate,
      'passportPlaceOfIssue': passportPlaceOfIssue,
      'birthPlace': birthPlace,
      'dob': dob,
      'nationality': nationality,
      'additionalComment': additionalComment,
    };
  }

  // Create model from Firestore snapshot if you need to read data back
  factory TravelDetails.fromMap(Map<String, dynamic> map) {
    return TravelDetails(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      methodOfArrival: map['methodOfArrival'] ?? '',
      arrivalFlightNumber: map['arrivalFlightNumber'] ?? '',
      arrivalDate: map['arrivalDate'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      departureMethod: map['departureMethod'] ?? '',
      departureFlightNumber: map['departureFlightNumber'] ?? '',
      departureDate: map['departureDate'] ?? '',
      departureTime: map['departureTime'] ?? '',
      passportNumber: map['passportNumber'] ?? '',
      passportIssuingDate: map['passportIssuingDate'] ?? '',
      passportPlaceOfIssue: map['passportPlaceOfIssue'] ?? '',
      birthPlace: map['birthPlace'] ?? '',
      dob: map['dob'] ?? '',
      nationality: map['nationality'] ?? '',
      additionalComment: map['additionalComment'] ?? '',
    );
  }
}
