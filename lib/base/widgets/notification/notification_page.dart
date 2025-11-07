import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'Upload Approved', 'body': 'Your resource for CSC201 is now live.'},
      {'title': 'New Chat Message', 'body': 'Ayo: “Hey, did you check the material?”'},
    ];

    return Scaffold(
      appBar: AppBar(
        title:  Text('Notifications'),
        centerTitle: true,
        leading: IconButton(
          icon:  Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.subText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding:  EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) =>  Divider(),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return ListTile(
            title: Text(
              notif['title']!,
              style:  TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(notif['body']!),
            leading: Icon(FluentSystemIcons.ic_fluent_alert_regular),
          );
        },
      ),
    );
  }
}
