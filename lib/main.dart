import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'core/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);

    WindowOptions windowOptions = const WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener, WindowListener {
  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initSystemTray();
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  void _initSystemTray() async {
    String iconPath =
        Platform.isWindows ? 'assets/app-icon.ico' : 'assets/app-icon.png';

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await trayManager.setContextMenu(menu);
      await trayManager.setIcon(iconPath);
    }
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      windowManager.setPreventClose(false);
      windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        title: 'Fortnite Ranked Tracker',
        home: const AuthenticationHandler(),
      ),
    );
  }
}

class AuthenticationHandler extends StatelessWidget {
  const AuthenticationHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FutureBuilder(
      future: authProvider.initializeAuth(),
      builder: (ctx, authResultSnapshot) =>
          authResultSnapshot.connectionState == ConnectionState.waiting
              ? const SplashScreen()
              : authProvider.accessToken.isNotEmpty
                  ? MainScreen(authProvider: authProvider)
                  : const AuthScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
