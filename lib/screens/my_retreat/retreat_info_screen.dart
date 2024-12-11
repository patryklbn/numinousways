import 'package:flutter/material.dart';

class RetreatInfoScreen extends StatelessWidget {
  const RetreatInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Temporary static data. In the future, fetch from Firebase.
    final retreatDate = 'March 12 - March 19, 2025';
    final retreatLocation = 'Sanctuary Wellness Center';
    final retreatAddress = '123 Forest Road, Green Valley';

    return Scaffold(
      appBar: AppBar(
        title: Text('Retreat Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Retreat Date:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(retreatDate, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Location:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(retreatLocation, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Address:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(retreatAddress, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
