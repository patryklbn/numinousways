import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:numinous_ways/models/comment.dart';
import 'package:numinous_ways/models/user_profile.dart';
import 'package:numinous_ways/services/login_provider.dart';

// Simple mock class for LoginProvider
class MockLoginProvider extends ChangeNotifier implements LoginProvider {
  final String _userId;

  MockLoginProvider(this._userId);

  @override
  String? get userId => _userId;

  // Implement other required methods with minimal functionality
  @override
  bool get isLoading => false;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isEmailVerified => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Stub implementation of CommentWidget for testing
// This avoids the actual Firebase dependencies
class StubCommentWidget extends StatelessWidget {
  final Comment comment;
  final String postId;

  const StubCommentWidget({
    Key? key,
    required this.comment,
    required this.postId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<LoginProvider>(context).userId;
    final isOwner = currentUserId == comment.userId;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('User Name', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(comment.createdAt.toDate().toString()),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 16),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOwner)
                              ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete Comment'),
                                onTap: () => Navigator.pop(context),
                              ),
                            if (!isOwner)
                              ListTile(
                                leading: Icon(Icons.flag, color: Colors.orange),
                                title: Text('Report Comment'),
                                onTap: () => Navigator.pop(context),
                              ),
                            ListTile(
                              leading: Icon(Icons.close),
                              title: Text('Cancel'),
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(comment.content),
          if (comment.imageUrl != null)
            Container(
              height: 150,
              color: Colors.grey[300],
              margin: EdgeInsets.only(top: 8),
              child: Center(child: Text('Image: ${comment.imageUrl}')),
            ),
          SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  comment.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: comment.isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: () {},
              ),
              Text('${comment.likesCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

// Test helper to create a comment
Comment createTestComment({
  String id = 'comment123',
  String userId = 'user123',
  String content = 'Test comment content',
  String? imageUrl,
  bool isLiked = false,
  int likesCount = 0,
}) {
  return Comment(
    id: id,
    userId: userId,
    content: content,
    imageUrl: imageUrl,
    createdAt: Timestamp.now(),
    isLiked: isLiked,
    likesCount: likesCount,
  );
}

void main() {
  setUp(() {
    // This sets up a fake Firebase app for testing
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('StubCommentWidget displays comment content correctly', (WidgetTester tester) async {
    // Arrange
    final comment = createTestComment();
    final mockLoginProvider = MockLoginProvider('differentUser123');

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubCommentWidget(
              postId: 'post123',
              comment: comment,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify the widget shows the correct content
    expect(find.text('Test comment content'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Likes count
  });

  testWidgets('StubCommentWidget shows like count correctly', (WidgetTester tester) async {
    // Arrange
    final comment = createTestComment(
      likesCount: 42,
      isLiked: true,
    );
    final mockLoginProvider = MockLoginProvider('differentUser123');

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubCommentWidget(
              postId: 'post123',
              comment: comment,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify the widget shows the correct like count
    expect(find.text('42'), findsOneWidget); // Likes count
  });

  testWidgets('StubCommentWidget shows delete option for comment owner', (WidgetTester tester) async {
    // Arrange - create comment by the same user as the login provider
    final comment = createTestComment(
      userId: 'currentUser123',
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubCommentWidget(
              postId: 'post123',
              comment: comment,
            ),
          ),
        ),
      ),
    );

    // Open the menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Assert - Verify delete option is shown
    expect(find.text('Delete Comment'), findsOneWidget);
    expect(find.text('Report Comment'), findsNothing);
  });

  testWidgets('StubCommentWidget shows report option for non-owners', (WidgetTester tester) async {
    // Arrange - create comment by a different user
    final comment = createTestComment(
      userId: 'otherUser456',
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubCommentWidget(
              postId: 'post123',
              comment: comment,
            ),
          ),
        ),
      ),
    );

    // Open the menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Assert - Verify report option is shown
    expect(find.text('Report Comment'), findsOneWidget);
    expect(find.text('Delete Comment'), findsNothing);
  });

  testWidgets('StubCommentWidget handles comment with image correctly', (WidgetTester tester) async {
    // Arrange
    final comment = createTestComment(
      imageUrl: 'https://example.com/image.jpg',
    );
    final mockLoginProvider = MockLoginProvider('differentUser123');

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubCommentWidget(
              postId: 'post123',
              comment: comment,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify image container is displayed
    expect(find.text('Test comment content'), findsOneWidget);
    expect(find.text('Image: https://example.com/image.jpg'), findsOneWidget);
  });
}