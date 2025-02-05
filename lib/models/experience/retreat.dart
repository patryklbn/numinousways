import 'package:cloud_firestore/cloud_firestore.dart';

class Retreat {
  final String id;
  final String title;
  final List<String> shortDescription;
  final List<String> detailedDescription;
  final String mushroomTitle;
  final List<String> mushroomDescription;
  final String truffleTitle;
  final List<String> truffleDescription;
  final List<String> spotifyLinks;
  final String location;
  final String? cardImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int cost;
  final List<String> facilitatorIds;
  final String? venueId;

  // Feature flags
  final bool showFellowNuminauts;
  final bool showMushroomOrder;
  final bool showTruffleOrder;
  final bool showMEQ;
  final bool showFeedback;
  final bool isArchived;

  final double? latitude;
  final double? longitude;

  // Travel fields
  final List<String> travelDescription;
  final List<String> meetingLocation;
  final List<String> returnLocation;
  final List<String> retreatAddress;
  final List<String> transportationRequest;

  Retreat({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.detailedDescription,
    required this.mushroomDescription,
    required this.mushroomTitle,
    this.truffleTitle = '',
    this.truffleDescription = const [],
    required this.spotifyLinks,
    required this.location,
    this.cardImageUrl,
    required this.startDate,
    required this.endDate,
    required this.cost,
    this.showFellowNuminauts = false,
    this.showMushroomOrder = false,
    this.showTruffleOrder = false,
    this.showMEQ = false,
    this.showFeedback = false,
    this.isArchived = false,
    this.facilitatorIds = const [],
    this.venueId,
    this.latitude,
    this.longitude,

    // Travel & address
    this.travelDescription = const [],
    this.meetingLocation = const [],
    this.returnLocation = const [],
    this.retreatAddress = const [],
    this.transportationRequest = const [],
  });

  factory Retreat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Retreat(
      id: doc.id,
      title: data['title'] ?? '',
      shortDescription: List<String>.from(data['shortDescription'] ?? []),
      detailedDescription: List<String>.from(data['detailedDescription'] ?? []),
      mushroomDescription: List<String>.from(data['mushroomDescription'] ?? []),
      mushroomTitle: data['mushroomTitle'] ?? '',
      truffleTitle: data['truffleTitle'] ?? '',
      truffleDescription: List<String>.from(data['truffleDescription'] ?? []),
      spotifyLinks: List<String>.from(data['spotifyLinks'] ?? []),
      location: data['location'] ?? '',
      cardImageUrl: data['cardImageUrl'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      cost: data['cost'] ?? 0,
      showFellowNuminauts: data['showFellowNuminauts'] ?? false,
      showMushroomOrder: data['showMushroomOrder'] ?? false,
      showTruffleOrder: data['showTruffleOrder'] ?? false,
      showMEQ: data['showMEQ'] ?? false,
      showFeedback: data['showFeedback'] ?? false,
      isArchived: data['isArchived'] ?? false,
      facilitatorIds: data['facilitatorIds'] == null
          ? []
          : List<String>.from(data['facilitatorIds']),
      venueId: data['venueId'],
      latitude: data['latitude'] != null
          ? (data['latitude'] as num).toDouble()
          : null,
      longitude: data['longitude'] != null
          ? (data['longitude'] as num).toDouble()
          : null,

      // Travel & address
      travelDescription: List<String>.from(data['travelDescription'] ?? []),
      meetingLocation: List<String>.from(data['meetingLocation'] ?? []),
      returnLocation: List<String>.from(data['returnLocation'] ?? []),
      retreatAddress: List<String>.from(data['retreatAddress'] ?? []),
      transportationRequest: List<String>.from(data['transportationRequest'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'detailedDescription': detailedDescription,
      'mushroomDescription': mushroomDescription,
      'mushroomTitle': mushroomTitle,
      'truffleTitle': truffleTitle,
      'truffleDescription': truffleDescription,
      'spotifyLinks': spotifyLinks,
      'location': location,
      'cardImageUrl': cardImageUrl,
      'startDate': startDate,
      'endDate': endDate,
      'cost': cost,
      'showFellowNuminauts': showFellowNuminauts,
      'showMushroomOrder': showMushroomOrder,
      'showTruffleOrder': showTruffleOrder,
      'showMEQ': showMEQ,
      'showFeedback': showFeedback,
      'isArchived': isArchived,
      'facilitatorIds': facilitatorIds,
      if (venueId != null) 'venueId': venueId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,

      'travelDescription': travelDescription,
      'meetingLocation': meetingLocation,
      'returnLocation': returnLocation,
      'retreatAddress': retreatAddress,
      'transportationRequest': transportationRequest,
    };
  }
}
