// lib/screens/main_app_with_drawer.dart

import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/timeline/timeline_screen.dart';

class MainAppWithDrawer extends StatelessWidget {
  const MainAppWithDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(), // No longer pass userId
      appBar: AppBar(title: Text('Your App Name')),
      body: TimelineScreen(), // Default screen after login
    );
  }
}
