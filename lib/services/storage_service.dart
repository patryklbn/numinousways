import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  // Constructor with dependency injection
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  // Upload Facilitator Photo
  Future<String> uploadFacilitatorPhoto(File file, String facilitatorId) async {
    try {
      Reference ref = _storage.ref().child('facilitators/$facilitatorId.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading facilitator photo: $e');
      rethrow;
    }
  }

  // Upload Venue Image
  Future<String> uploadVenueImage(File file, String venueId, String imageName) async {
    try {
      Reference ref = _storage.ref().child('venues/$venueId/$imageName.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading venue image: $e');
      rethrow;
    }
  }

  // Delete Facilitator Photo
  Future<void> deleteFacilitatorPhoto(String facilitatorId) async {
    try {
      Reference ref = _storage.ref().child('facilitators/$facilitatorId.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting facilitator photo: $e');
      rethrow;
    }
  }

  // Delete Venue Image
  Future<void> deleteVenueImage(String venueId, String imageName) async {
    try {
      Reference ref = _storage.ref().child('venues/$venueId/$imageName.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting venue image: $e');
      rethrow;
    }
  }
}