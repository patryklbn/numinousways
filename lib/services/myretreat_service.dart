import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/facilitator.dart';
import '../models/venue.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyRetreatService {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  MyRetreatService({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  // -------------------------
  // Facilitator Methods
  // -------------------------
  Stream<List<Facilitator>> getFacilitators(String currentUserId) {
    return _firestoreService.getFacilitators();
  }

  Future<void> addFacilitator(Facilitator facilitator, File photoFile, String currentUserId) async {
    String photoUrl = await _storageService.uploadFacilitatorPhoto(photoFile, facilitator.name.replaceAll(' ', '_'));

    Facilitator newFacilitator = Facilitator(
      id: '',
      name: facilitator.name,
      role: facilitator.role,
      photoUrl: photoUrl,
    );

    await _firestoreService.addFacilitator(newFacilitator);
  }

  Future<void> updateFacilitator(Facilitator facilitator, {File? newPhotoFile, required String currentUserId}) async {
    String updatedPhotoUrl = facilitator.photoUrl;

    if (newPhotoFile != null) {
      updatedPhotoUrl = await _storageService.uploadFacilitatorPhoto(
        newPhotoFile,
        facilitator.name.replaceAll(' ', '_'),
      );
    }

    Facilitator updatedFacilitator = Facilitator(
      id: facilitator.id,
      name: facilitator.name,
      role: facilitator.role,
      photoUrl: updatedPhotoUrl,
    );

    await _firestoreService.updateFacilitator(updatedFacilitator);
  }

  Future<void> deleteFacilitator(String facilitatorId, String currentUserId) async {
    await _storageService.deleteFacilitatorPhoto(facilitatorId);
    await _firestoreService.deleteFacilitator(facilitatorId);
  }

  // -------------------------
  // Venue Methods
  // -------------------------
  Stream<List<Venue>> getVenues(String currentUserId) {
    return _firestoreService.getVenues();
  }

  Future<void> addVenue(Venue venue, List<File> imageFiles, String currentUserId) async {
    List<String> imageUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      String imageName = '${venue.name.replaceAll(' ', '_')}_$i';
      String imageUrl = await _storageService.uploadVenueImage(
        imageFiles[i],
        venue.name.replaceAll(' ', '_'),
        imageName,
      );
      imageUrls.add(imageUrl);
    }

    Venue newVenue = Venue(
      id: '',
      name: venue.name,
      description: venue.description,
      images: imageUrls,
    );

    await _firestoreService.addVenue(newVenue);
  }

  Future<void> updateVenue(Venue venue, {List<File>? newImageFiles, required String currentUserId}) async {
    List<String> updatedImageUrls = venue.images;

    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      for (int i = 0; i < newImageFiles.length; i++) {
        String imageName = '${venue.name.replaceAll(' ', '_')}_new_$i';
        String imageUrl = await _storageService.uploadVenueImage(
          newImageFiles[i],
          venue.name.replaceAll(' ', '_'),
          imageName,
        );
        updatedImageUrls.add(imageUrl);
      }
    }

    Venue updatedVenue = Venue(
      id: venue.id,
      name: venue.name,
      description: venue.description,
      images: updatedImageUrls,
    );

    await _firestoreService.updateVenue(updatedVenue);
  }

  Future<void> deleteVenue(String venueId, List<String> imageUrls, String currentUserId) async {
    for (String imageUrl in imageUrls) {
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    }

    await _firestoreService.deleteVenue(venueId);
  }

  Future<Venue?> getVenueById(String venueId) async {
    final docSnap = await FirebaseFirestore.instance
        .collection('venues')
        .doc(venueId)
        .get();
    if (!docSnap.exists) return null;
    return Venue.fromDocument(docSnap);
  }

}
