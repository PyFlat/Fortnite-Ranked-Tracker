import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'core/api_service.dart';
import 'core/avatar_manager.dart';
import 'core/talker_service.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/no_connection_screen.dart';

void main() async {
  talker.verbose("Talker initialization completed");

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      runApp(MyApp());
    },
    (Object error, StackTrace stack) {
      talker.handle(error, stack, 'Uncaught app exception');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Timer timer;
  late Dio dio;
  late InternetConnection connectionChecker;
  late StreamSubscription<InternetConnection> subscription;

  bool _isOffline = false;

  @override
  void initState() {
    dio = Dio();
    ApiService().init(dio);
    AvatarManager().initialize("assets/avatar-images");

    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      connectionChecker = InternetConnection();
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
    }

    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [TalkerRouteObserver(talker)],
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      title: 'Fortnite Ranked Tracker',
      home: SafeArea(
          child: _isOffline
              ? const NoConnectionScreen()
              : FirebaseAuthCheck(
                  dio: dio,
                )),
    );
  }
}

class FirebaseAuthCheck extends StatelessWidget {
  const FirebaseAuthCheck({super.key, required this.dio});

  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>(
      create: (_) => FirebaseAuth.instance.authStateChanges(),
      initialData: null,
      child: AuthWrapper(
        dio: dio,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key, required this.dio});

  final Dio dio;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return LoginPage(dio: dio);
    } else {
      return MainScreen(dio: dio);
    }
  }
}
