import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numinous_ways/models/post.dart';
import 'package:numinous_ways/models/user_profile.dart';
import 'package:numinous_ways/services/login_provider.dart';

// Simple mock class for LoginProvider
class MockLoginProvider extends ChangeNotifier implements LoginProvider {
  final String _userId;

  MockLoginProvider(this._userId);

  @override
  String? get userId => _userId;


  @override
  bool get isLoading => false;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isEmailVerified => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Stub implementation of PostWidget for testing
class StubPostWidget extends StatelessWidget {
  final Post post;
  final ValueNotifier<bool> isCommentsScreenOpen;
  final Function(Post updatedPost)? onPostLikeToggled;
  final bool truncateText;
  final int? maxLines;
  final UserProfile? userProfile;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onReportPressed;

  const StubPostWidget({
    Key? key,
    required this.post,
    required this.isCommentsScreenOpen,
    this.onPostLikeToggled,
    this.truncateText = true,
    this.maxLines = 3,
    this.userProfile,
    this.onLikePressed,
    this.onCommentPressed,
    this.onDeletePressed,
    this.onReportPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<LoginProvider>(context).userId;
    final isOwner = currentUserId == post.userId;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFBA8FDB),
              child: userProfile?.profileImageUrl != null
                  ? null
                  : const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              userProfile?.name ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              post.createdAt.toDate().toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'delete' && isOwner) {
                  onDeletePressed?.call();
                } else if (value == 'report' && !isOwner) {
                  onReportPressed?.call();
                }
              },
              itemBuilder: (BuildContext context) => [
                if (isOwner)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Post'),
                      ],
                    ),
                  ),
                if (!isOwner)
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Report Post'),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Post content
          GestureDetector(
            onTap: onCommentPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.content.isNotEmpty)
                    Text(
                      post.content,
                      maxLines: truncateText ? maxLines : null,
                      overflow: truncateText ? TextOverflow.ellipsis : TextOverflow.visible,
                    ),

                  if (truncateText && post.content.length > 100)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        'Read more',
                        style: TextStyle(
                          color: Color(0xFF6A0DAD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  if (post.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text('Image: ${post.imageUrl}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Like and comment buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Like button
                InkWell(
                  onTap: onLikePressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.isLiked ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            color: post.isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Comment button
                InkWell(
                  onTap: isCommentsScreenOpen.value ? null : onCommentPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }
}

// Test helper to create a post
Post createTestPost({
  String id = 'post123',
  String userId = 'user123',
  String content = 'Test post content',
  String? imageUrl,
  bool isLiked = false,
  int likesCount = 0,
  int commentsCount = 0,
  DateTime? createdAt,
}) {
  return Post(
    id: id,
    userId: userId,
    content: content,
    imageUrl: imageUrl,
    createdAt: Timestamp.fromDate(createdAt ?? DateTime.now()),
    isLiked: isLiked,
    likesCount: likesCount,
    commentsCount: commentsCount,
  );
}

void main() {
  setUp(() {
    // This sets up the testing environment
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('StubPostWidget displays post content correctly', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost();
    final mockLoginProvider = MockLoginProvider('differentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    bool likePressed = false;
    bool commentPressed = false;

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              onLikePressed: () => likePressed = true,
              onCommentPressed: () => commentPressed = true,
            ),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Test post content'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('StubPostWidget shows likes count correctly', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost(
      likesCount: 42,
      isLiked: true,
    );
    final mockLoginProvider = MockLoginProvider('differentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify the widget shows the correct like count
    expect(find.text('42'), findsOneWidget); // Likes count
    expect(find.byIcon(Icons.favorite), findsOneWidget); // Filled heart icon
  });

  testWidgets('StubPostWidget shows comments count correctly', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost(
      commentsCount: 15,
    );
    final mockLoginProvider = MockLoginProvider('differentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify the widget shows the correct comments count
    expect(find.text('15'), findsOneWidget); // Comments count
  });

  testWidgets('StubPostWidget shows image placeholder when image URL is provided', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost(
      imageUrl: 'https://example.com/image.jpg',
    );
    final mockLoginProvider = MockLoginProvider('differentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify image representation is shown
    expect(find.text('Image: https://example.com/image.jpg'), findsOneWidget);
  });

  testWidgets('StubPostWidget shows delete option for post owner', (WidgetTester tester) async {
    // Arrange - create post by the same user as the login provider
    final post = createTestPost(
      userId: 'currentUser123',
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    bool deletePressed = false;

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              onDeletePressed: () => deletePressed = true,
            ),
          ),
        ),
      ),
    );

    // Open the menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Assert - Verify delete option is shown
    expect(find.text('Delete Post'), findsOneWidget);
    expect(find.text('Report Post'), findsNothing);

    // Tap on delete and verify callback
    await tester.tap(find.text('Delete Post'));
    await tester.pump();
    expect(deletePressed, isTrue);
  });

  testWidgets('StubPostWidget shows report option for non-owners', (WidgetTester tester) async {
    // Arrange - create post by a different user
    final post = createTestPost(
      userId: 'otherUser456',
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    bool reportPressed = false;

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              onReportPressed: () => reportPressed = true,
            ),
          ),
        ),
      ),
    );

    // Open the menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Assert - Verify report option is shown
    expect(find.text('Report Post'), findsOneWidget);
    expect(find.text('Delete Post'), findsNothing);

    // Tap on report and verify callback
    await tester.tap(find.text('Report Post'));
    await tester.pump();
    expect(reportPressed, isTrue);
  });

  testWidgets('Tapping like button triggers callback', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost(
      likesCount: 5,
      isLiked: false,
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    bool likePressed = false;

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              onLikePressed: () => likePressed = true,
            ),
          ),
        ),
      ),
    );

    // Find and tap like button
    final likeFinder = find.byIcon(Icons.favorite_border);
    expect(likeFinder, findsOneWidget);
    await tester.tap(likeFinder);
    await tester.pump();

    // Assert callback was triggered
    expect(likePressed, isTrue);
  });

  testWidgets('Tapping comment button triggers callback when comments screen is not open', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost();
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false); // Not open

    bool commentPressed = false;

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              onCommentPressed: () => commentPressed = true,
            ),
          ),
        ),
      ),
    );

    // Find and tap comment button
    final commentFinder = find.byIcon(Icons.comment_outlined);
    expect(commentFinder, findsOneWidget);
    await tester.tap(commentFinder);
    await tester.pump();

    // Assert callback was triggered
    expect(commentPressed, isTrue);
  });

  testWidgets('Long content gets truncated with Read more', (WidgetTester tester) async {
    // Arrange
    final longContent = 'This is a very long post content that should be truncated. ' * 10;
    final post = createTestPost(
      content: longContent,
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              isCommentsScreenOpen: commentsNotifier,
              truncateText: true,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify Read more is shown
    expect(find.text('Read more'), findsOneWidget);
  });

  testWidgets('UserProfile data is displayed when provided', (WidgetTester tester) async {
    // Arrange
    final post = createTestPost();
    final userProfile = UserProfile(
      id: 'user123',
      name: 'Test User',
      profileImageUrl: null,
    );
    final mockLoginProvider = MockLoginProvider('currentUser123');
    final commentsNotifier = ValueNotifier<bool>(false);

    // Act - Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<LoginProvider>.value(
            value: mockLoginProvider,
            child: StubPostWidget(
              post: post,
              userProfile: userProfile,
              isCommentsScreenOpen: commentsNotifier,
            ),
          ),
        ),
      ),
    );

    // Assert - Verify user name is displayed
    expect(find.text('Test User'), findsOneWidget);
  });
}