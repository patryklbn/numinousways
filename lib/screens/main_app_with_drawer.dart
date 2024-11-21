import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/timeline/timeline_screen.dart';

class MainAppWithDrawer extends StatelessWidget {
  final String? userId;

  const MainAppWithDrawer({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("MainAppWithDrawer loaded with userId: $userId");  // Debug message

    return Scaffold(
      drawer: AppDrawer(userId: userId ?? ''), // Pass userId to AppDrawer
      appBar: AppBar(title: Text('Your App Name')),
      body: TimelineScreen(), // Default screen after login
    );
  }
}
