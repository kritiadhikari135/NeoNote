import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Notification',
      onItemSelected: (page) {},
      body: Container(
        color: Colors.white,
        child: const Center(
          child: Text(
            'This is the Notification Page',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
