import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:numinous_ways/services/ai_gallery_service.dart';


void main() {
  group('AiGalleryService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late MockHttpClient mockHttpClient;
    late MockUuid mockUuid;
    late AiGalleryService aiGalleryService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      mockHttpClient = MockHttpClient();
      mockUuid = MockUuid();

      // Setup default responses
      mockHttpClient.mockGetResponse = http.Response.bytes(Uint8List(10), 200);
      mockHttpClient.mockPostResponse = http.Response(
        json.encode({
          'data': [
            {'url': 'https://test-openai-image-url.com/image.jpg'}
          ]
        }),
        200,
      );
      mockStorage.mockDownloadUrl = 'https://test-download-url.com/image.jpg';
      mockUuid.mockUuidValue = 'test-uuid';

      aiGalleryService = AiGalleryService(
        firestore: fakeFirestore,
        storage: mockStorage,
        httpClient: mockHttpClient,
        uuid: mockUuid,
      );
    });

    test('generateImageFromPrompt returns URL when successful', () async {
      // Act
      final result = await aiGalleryService.generateImageFromPrompt('A beautiful sunset');

      // Assert
      expect(result, 'https://test-openai-image-url.com/image.jpg');
      expect(mockHttpClient.postCalled, true);
    });

    test('generateImageFromPrompt throws exception when API fails', () async {
      // Arrange
      mockHttpClient.mockPostResponse = http.Response('{"error":{"message":"Error"}}', 400);

      // Act & Assert
      expect(
              () => aiGalleryService.generateImageFromPrompt('A beautiful sunset'),
          throwsException
      );
    });

    // Skip test for uploadAiImage since it uses FlutterImageCompress

    test('addAiImage saves image data to Firestore', () async {
      // Arrange
      final imageUrls = {
        'thumbnailUrl': 'https://test-thumb-url.com/image.jpg',
        'detailUrl': 'https://test-detail-url.com/image.jpg',
        'sizeKB': '100.0'
      };

      // Act
      await aiGalleryService.addAiImage(
        prompt: 'Test prompt',
        imageUrls: imageUrls,
        userId: 'test-user-id',
        userName: 'Test User',
      );

      // Assert
      final snapshot = await fakeFirestore.collection('ai_images').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['prompt'], 'Test prompt');
      expect(snapshot.docs.first.data()['imageUrl'], 'https://test-detail-url.com/image.jpg');
      expect(snapshot.docs.first.data()['thumbnailUrl'], 'https://test-thumb-url.com/image.jpg');
      expect(snapshot.docs.first.data()['userId'], 'test-user-id');
      expect(snapshot.docs.first.data()['userName'], 'Test User');
      expect(snapshot.docs.first.data()['sizeKB'], '100.0');
      expect(snapshot.docs.first.data()['shouldKeep'], false);
    });

    test('toggleLike adds user to likes array', () async {
      // Arrange - create a test document
      final docRef = await fakeFirestore.collection('ai_images').add({
        'prompt': 'Test prompt',
        'likes': <String>[],
        'shouldKeep': false,
      });

      // Act
      await aiGalleryService.toggleLike(
        docId: docRef.id,
        userId: 'test-user-id',
        currentlyLiked: false,
      );

      // Assert
      final doc = await fakeFirestore.collection('ai_images').doc(docRef.id).get();
      final likes = List<String>.from(doc.data()!['likes']);
      expect(likes.contains('test-user-id'), true);
      expect(likes.length, 1);
    });

    test('toggleLike removes user from likes array', () async {
      // Arrange - create a test document with the user already liking it
      final docRef = await fakeFirestore.collection('ai_images').add({
        'prompt': 'Test prompt',
        'likes': <String>['test-user-id', 'other-user-1', 'other-user-2'],
        'shouldKeep': true,
      });

      // Act
      await aiGalleryService.toggleLike(
        docId: docRef.id,
        userId: 'test-user-id',
        currentlyLiked: true,
      );

      // Assert
      final doc = await fakeFirestore.collection('ai_images').doc(docRef.id).get();
      final likes = List<String>.from(doc.data()!['likes']);
      expect(likes.contains('test-user-id'), false);
      expect(likes.length, 2);
    });

    test('deleteAiImage deletes image from Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('ai_images').add({
        'prompt': 'Test prompt',
        'thumbnailUrl': 'https://test-url.com/image.jpg',
        'detailUrl': 'https://test-url.com/image.jpg',
        'imageUrl': 'https://test-url.com/image.jpg',
        'sizeKB': '100.0',
      });

      // Act
      await aiGalleryService.deleteAiImage(docRef.id);

      // Assert
      final doc = await fakeFirestore.collection('ai_images').doc(docRef.id).get();
      expect(doc.exists, false);
    });

    test('getStorageStats returns storage stats from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('app_stats').doc('storage').set({
        'totalSizeKB': 1000.0,
        'totalSizeMB': 1.0,
        'imageCount': 10,
        'lastUpdated': Timestamp.now(),
      });

      // Act
      final result = await aiGalleryService.getStorageStats();

      // Assert
      expect(result['totalSizeKB'], 1000.0);
      expect(result['totalSizeMB'], 1.0);
      expect(result['imageCount'], 10);
      expect(result['lastUpdated'], isA<Timestamp>());
    });

    test('deleteAllUserImages deletes all images for a user', () async {
      // Create test documents
      await fakeFirestore.collection('ai_images').add({
        'prompt': 'Test prompt 1',
        'userId': 'test-user-id',
        'thumbnailUrl': 'https://test-url.com/image1.jpg',
        'detailUrl': 'https://test-url.com/image1.jpg',
        'imageUrl': 'https://test-url.com/image1.jpg',
        'sizeKB': '100.0',
      });

      await fakeFirestore.collection('ai_images').add({
        'prompt': 'Test prompt 2',
        'userId': 'test-user-id',
        'thumbnailUrl': 'https://test-url.com/image2.jpg',
        'detailUrl': 'https://test-url.com/image2.jpg',
        'imageUrl': 'https://test-url.com/image2.jpg',
        'sizeKB': '150.0',
      });

      await fakeFirestore.collection('ai_images').add({
        'prompt': 'Other user prompt',
        'userId': 'other-user-id',
        'thumbnailUrl': 'https://test-url.com/other.jpg',
        'detailUrl': 'https://test-url.com/other.jpg',
        'imageUrl': 'https://test-url.com/other.jpg',
        'sizeKB': '200.0',
      });

      // Act
      await aiGalleryService.deleteAllUserImages('test-user-id');

      // Assert
      final snapshot = await fakeFirestore.collection('ai_images').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['userId'], 'other-user-id');
    });
  });
}

// mock classes
class MockHttpClient implements http.Client {
  bool postCalled = false;
  bool getCalled = false;
  http.Response? mockPostResponse;
  http.Response? mockGetResponse;

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    postCalled = true;
    return mockPostResponse ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    getCalled = true;
    return mockGetResponse ?? http.Response('', 404);
  }

  @override
  void close() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFirebaseStorage implements FirebaseStorage {
  String mockDownloadUrl = '';

  @override
  Reference ref([String? path]) {
    return MockReference(mockDownloadUrl);
  }

  @override
  Reference refFromURL(String url) {
    return MockReference(mockDownloadUrl);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockReference implements Reference {
  final String downloadUrl;

  MockReference(this.downloadUrl);

  @override
  Reference child(String path) {
    return this;
  }

  @override
  Future<String> getDownloadURL() async {
    return downloadUrl;
  }

  @override
  Future<void> delete() async {}

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    return MockUploadTask(this);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUploadTask implements UploadTask {
  final MockReference reference;

  MockUploadTask(this.reference);

  @override
  TaskSnapshot get snapshot => MockTaskSnapshot(reference);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTaskSnapshot implements TaskSnapshot {
  final MockReference reference;

  MockTaskSnapshot(this.reference);

  @override
  Reference get ref => reference;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUuid implements Uuid {
  String mockUuidValue = 'mock-uuid';

  @override
  String v4({dynamic config, Map<String, dynamic>? options}) {
    return mockUuidValue;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}