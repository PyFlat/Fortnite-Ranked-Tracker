import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'core/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  final talker =
      TalkerFlutter.init(settings: TalkerSettings(useConsoleLogs: false));
  talker.verbose("Talker initialization completed");
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        if (!(await FlutterSingleInstance.platform.isFirstInstance())) {
          await setShowInstance(true);
          exit(0);
        }
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
      runApp(MyApp(talker: talker));
    },
    (Object error, StackTrace stack) {
      talker.handle(error, stack, 'Uncaught app exception');
    },
  );
}

Future<String> getFilePath() async {
  String directory = (await getTemporaryDirectory()).path;
  return "$directory/fortnite-ranked-tracker-show.txt";
}

Future<void> setShowInstance(bool value) async {
  final file = File(await getFilePath());
  final content = value ? '1' : '0';
  await file.writeAsString(content);
}

Future<bool> getShowInstance() async {
  final file = File(await getFilePath());

  if (await file.exists()) {
    final content = await file.readAsString();
    return content == '1';
  } else {
    await file.writeAsString('0');
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.talker});

  final Talker talker;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener, WindowListener {
  late Timer timer;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final result = await getShowInstance();
      if (result) {
        windowManager.show();
        await setShowInstance(false);
      }
    });
    _initSystemTray();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
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
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await trayManager.setIcon(iconPath);
      await trayManager.setContextMenu(menu);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit_app') {
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
        navigatorObservers: [TalkerRouteObserver(widget.talker)],
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        title: 'Fortnite Ranked Tracker',
        home: AuthenticationHandler(talker: widget.talker),
      ),
    );
  }
}

class AuthenticationHandler extends StatelessWidget {
  const AuthenticationHandler({super.key, required this.talker});

  final Talker talker;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FutureBuilder(
      future: authProvider.initializeAuth(),
      builder: (ctx, authResultSnapshot) =>
          authResultSnapshot.connectionState == ConnectionState.waiting
              ? const SplashScreen()
              : authProvider.accessToken.isNotEmpty
                  ? MainScreen(authProvider: authProvider, talker: talker)
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
