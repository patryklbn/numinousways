import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline"),
      ),
      body: Center(
        child: Text(
          "Timeline Screen",
          style: TextStyle(fontSize: 24, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
