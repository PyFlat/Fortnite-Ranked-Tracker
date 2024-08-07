import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(title: Text("Test"), tiles: [
            SettingsTile(
              leading: Icon(Icons.emoji_people),
              title: Text("Test"),
            )
          ])
        ],
      ),
    );
  }
}
