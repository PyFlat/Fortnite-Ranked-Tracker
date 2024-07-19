import 'package:auth_flow_example/core/rank_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auth Flow Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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
    RankService().init(context);

    return FutureBuilder(
      future: authProvider.initializeAuth(),
      builder: (ctx, authResultSnapshot) =>
          authResultSnapshot.connectionState == ConnectionState.waiting
              ? const SplashScreen()
              : authProvider.accessToken.isNotEmpty
                  ? MainScreen()
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
