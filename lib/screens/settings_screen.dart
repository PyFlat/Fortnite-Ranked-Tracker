import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(title: const Text("Test"), tiles: [
            SettingsTile(
              leading: const Icon(Icons.emoji_people),
              title: const Text("Test"),
            )
          ])
        ],
      ),
    );
  }
}
