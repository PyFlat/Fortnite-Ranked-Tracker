import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences prefs;
  late Future<void> _future;
  bool showAtStartup = true;
  bool autoStart = false;
  bool minimizeAsTray = true;

  @override
  void initState() {
    _future = _initializeSettings();

    super.initState();
  }

  Future<void> _initializeSettings() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      showAtStartup = prefs.getBool("showAtStartup") ?? true;
      autoStart = prefs.getBool("autoStart") ?? false;
      minimizeAsTray = prefs.getBool("minimizeAsTray") ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return SettingsList(
              sections: [
                SettingsSection(title: const Text("Application"), tiles: [
                  SettingsTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text("Logout"),
                    onPressed: (context) {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pop();
                    },
                  ),
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.visibility_rounded),
                    initialValue: showAtStartup,
                    onToggle: (newValue) {
                      setState(() {
                        showAtStartup = newValue;
                        prefs.setBool("showAtStartup", newValue);
                      });
                    },
                    title: const Text("Show window at startup"),
                    enabled: Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux
                        ? true
                        : false,
                  ),
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.start_rounded),
                    initialValue: autoStart,
                    onToggle: (newValue) async {
                      setState(() {
                        autoStart = newValue;
                        prefs.setBool("autoStart", newValue);
                      });
                      PackageInfo packageInfo =
                          await PackageInfo.fromPlatform();
                      launchAtStartup.setup(
                          appName: packageInfo.appName,
                          appPath: Platform.resolvedExecutable);

                      if (newValue) {
                        launchAtStartup.enable();
                      } else {
                        launchAtStartup.disable();
                      }
                    },
                    title: const Text("Autostart the Application"),
                    enabled:
                        (Platform.isWindows || Platform.isLinux) && !kDebugMode
                            ? true
                            : false,
                  ),
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.arrow_downward_rounded),
                    initialValue: minimizeAsTray,
                    onToggle: (newValue) async {
                      setState(() {
                        minimizeAsTray = newValue;
                        prefs.setBool("minimizeAsTray", newValue);
                      });
                      if (minimizeAsTray) {
                        windowManager.setPreventClose(true);
                      } else {
                        windowManager.setPreventClose(false);
                      }
                    },
                    title: const Text("Minimize to tray when closed"),
                    enabled:
                        Platform.isWindows || Platform.isLinux ? true : false,
                  )
                ]),
              ],
            );
          }),
    );
  }
}
