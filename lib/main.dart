import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Auth Flow Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthenticationHandler(),
      ),
    );
  }
}

class AuthenticationHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FutureBuilder(
      future: null, // Start the authentication process
      builder: (ctx, authResultSnapshot) => authResultSnapshot
                  .connectionState ==
              ConnectionState.waiting
          ? SplashScreen() // Show a loading screen while checking authentication state
          : authProvider.accessToken.isNotEmpty
              ? HomeScreen() // If authenticated, show the home screen
              : AuthScreen(), // If not authenticated, show the authentication screen
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
