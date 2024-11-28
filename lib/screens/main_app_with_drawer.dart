// lib/screens/main_app_with_drawer.dart

import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../screens/timeline/timeline_screen.dart';

// main_app_with_drawer.dart

class MainAppWithDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      body: TimelineScreen(),
    );
  }
}

