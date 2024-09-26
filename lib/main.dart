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
import 'package:fortnite_ranked_tracker/core/tournament_data_provider.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'core/epic_auth_provider.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
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
      if (Platform.isAndroid || Platform.isIOS) {
        await initializeService();
      }

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
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
  final connectionChecker = InternetConnectionChecker();
  late StreamSubscription<InternetConnectionChecker> subscription;
  bool _isOffline = false;

  @override
  void initState() {
    dio = Dio();
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBackgroundService().invoke("setAsForeground");
    }

    trayManager.addListener(this);
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    connectionChecker.onStatusChange.listen((InternetConnectionStatus status) {
      if (status == InternetConnectionStatus.connected) {
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
      final result = await getShowInstance();
      if (result) {
        windowManager.show();
        windowManager.focus();
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
    String iconPath =
        Platform.isWindows ? 'assets/tray-icon.ico' : 'assets/app-icon.png';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EpicAuthProvider(widget.talker)),
        ChangeNotifierProvider(create: (_) => TournamentDataProvider())
      ],
      child: MaterialApp(
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
      ),
    );
  }
}

class FirebaseAuthCheck extends StatelessWidget {
  const FirebaseAuthCheck({super.key, required this.talker, required this.dio});

  final Talker talker;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for Firebase to check the auth state, show a loading indicator
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          // If the user is logged in, show the HomePage
          return AuthenticationHandler(
            talker: talker,
            dio: dio,
          );
        } else {
          // If the user is not logged in, show the LoginPage
          return const LoginPage();
        }
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Image(
                    image: AssetImage(
                      "assets/app-icon.png",
                    ),
                    color: Colors.white,
                  ),
                  const Text(
                    "Fortnite Ranked Tracker",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: Colors.white, // Text color for dark mode
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Welcome back, you've been missed!",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors
                          .grey.shade400, // Softer color for secondary text
                    ),
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors
                            .grey.shade900, // Dark background for input field
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(
                              color: Colors.white), // Text color in input
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: "Email",
                            labelStyle: TextStyle(
                                color: Colors.grey.shade400), // Label color
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: "Password",
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                          obscureText: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  GestureDetector(
                    onTap: _login,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14)),
                          child: const Center(
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          )),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Not a member?",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        "Register now",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.redAccent,
              ),
              SizedBox(height: 20),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Please check your network settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
              SizedBox(height: 20),
              Text(
                'Trying to reconnect...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthenticationHandler extends StatelessWidget {
  const AuthenticationHandler(
      {super.key, required this.talker, required this.dio});

  final Talker talker;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<EpicAuthProvider>(context);

    return FutureBuilder(
      future: authProvider.initializeAuth(),
      builder: (ctx, authResultSnapshot) => authResultSnapshot
                  .connectionState ==
              ConnectionState.waiting
          ? const SplashScreen()
          : authProvider.accessToken.isNotEmpty
              ? MainScreen(authProvider: authProvider, talker: talker, dio: dio)
              : AuthScreen(
                  authProvider: authProvider, talker: talker, dio: dio),
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
