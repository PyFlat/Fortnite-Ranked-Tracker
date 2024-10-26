import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
// import 'package:fortnite_ranked_tracker/core/tournament_data_provider.dart';
import 'package:fortnite_ranked_tracker/screens/login_screen.dart';
import 'package:fortnite_ranked_tracker/screens/no_connection_screen.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'firebase_options.dart';
import 'screens/main_screen.dart';

void main() async {
  final talker =
      TalkerFlutter.init(settings: TalkerSettings(useConsoleLogs: false));
  talker.verbose("Talker initialization completed");

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await initializeService();
      }

      if (!kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        if (!(await FlutterSingleInstance.platform.isFirstInstance())) {
          await setShowInstance(true);
          exit(0);
        }

        await windowManager.ensureInitialized();
        if (prefs.getBool("minimizeAsTray") ?? true) {
          windowManager.setPreventClose(true);
        }

        WindowOptions windowOptions = const WindowOptions(
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
        );
        if (Platform.isWindows) {
          windowManager.setIcon("assets/tray-icon.ico");
        }
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          bool showWindow = prefs.getBool("showAtStartup") ?? true;
          if (showWindow || kDebugMode) {
            await windowManager.show();
          }
          await windowManager.focus();
        });
      }
      runApp(MyApp(talker: talker));
    },
    (Object error, StackTrace stack) {
      print(error);
      talker.handle(error, stack, 'Uncaught app exception');
    },
  );
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    debugPrint('App successfully running in background: ${DateTime.now()}');
  });
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

class _MyAppState extends State<MyApp>
    with TrayListener, WindowListener, WidgetsBindingObserver {
  late Timer timer;
  late Dio dio;
  final connectionChecker = InternetConnection();
  late StreamSubscription<InternetConnection> subscription;
  bool _isOffline = false;

  @override
  void initState() {
    dio = Dio();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FlutterBackgroundService().invoke("setAsForeground");
    }

    trayManager.addListener(this);
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    connectionChecker.onStatusChange.listen((InternetStatus status) {
      if (status == InternetStatus.connected) {
        setState(() {
          _isOffline = false;
        });
      } else {
        setState(() {
          _isOffline = true;
        });
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!kIsWeb) {
        final result = await getShowInstance();
        if (result) {
          windowManager.show();
          windowManager.focus();
          await setShowInstance(false);
        }
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
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      FlutterBackgroundService().invoke("stopService");
    }
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  void _initSystemTray() async {
    String iconPath = (!kIsWeb && Platform.isWindows)
        ? 'assets/tray-icon.ico'
        : 'assets/app-icon.png';

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
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
    windowManager.focus();
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
    return MaterialApp(
      navigatorObservers: [TalkerRouteObserver(widget.talker)],
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      title: 'Fortnite Ranked Tracker',
      home: SafeArea(
          child: _isOffline
              ? const NoConnectionScreen()
              : FirebaseAuthCheck(
                  talker: widget.talker,
                  dio: dio,
                )),
    );
  }
}

class FirebaseAuthCheck extends StatelessWidget {
  const FirebaseAuthCheck({super.key, required this.talker, required this.dio});

  final Talker talker;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return MainScreen(
            talker: talker,
            dio: dio,
          );
        } else {
          return LoginPage(
            dio: dio,
          );
        }
      },
    );
  }
}
