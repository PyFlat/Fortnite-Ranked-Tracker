import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.dio});

  final Dio dio;

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController =
      TextEditingController(text: "johannes.25406@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "test1234");
  late AnimationController _emailAnimationController;
  late AnimationController _passwordAnimationController;
  bool _emailIsEmpty = false;
  bool _passwordIsEmpty = false;

  bool isHover = false;

  bool _loginError = false;

  @override
  void initState() {
    super.initState();
    _emailAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _passwordAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _emailAnimationController.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.forward) {
          _emailIsEmpty = true;
        } else {
          _emailIsEmpty = false;
        }
      });
    });
    _passwordAnimationController.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.forward) {
          _passwordIsEmpty = true;
        } else {
          _passwordIsEmpty = false;
        }
      });
    });
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty) {
      _emailAnimationController.forward(from: 0);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _passwordAnimationController.forward(from: 0);
      return;
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = true;
        });
      }
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    _loginError
                        ? "Invalid email or password. Please try again."
                        : "",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                  ShakeTransition(
                    animationController: _emailAnimationController,
                    child: AuthenticationTextField(
                        passwordController: _emailController,
                        isEmpty: _emailIsEmpty,
                        labelText: "Email",
                        obscureText: false,
                        obscureTextOff: Icons.email_rounded),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  ShakeTransition(
                    animationController: _passwordAnimationController,
                    child: AuthenticationTextField(
                      passwordController: _passwordController,
                      isEmpty: _passwordIsEmpty,
                      labelText: "Password",
                      obscureText: true,
                      obscureTextOff: Icons.lock_open_rounded,
                      obscureTextOn: Icons.lock_rounded,
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  MouseRegion(
                    onEnter: (event) => setState(() {
                      isHover = true;
                    }),
                    onExit: (event) => setState(() {
                      isHover = false;
                    }),
                    child: GestureDetector(
                      onTap: _login,
                      child: Stack(
                        children: [
                          Padding(
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
                          if (isHover)
                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                        ],
                      ),
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

class ShakeTransition extends StatelessWidget {
  final Widget child;
  final AnimationController animationController;

  const ShakeTransition(
      {super.key, required this.child, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final sineValue = sin(2 * 2 * pi * animationController.value);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

class AuthenticationTextField extends StatefulWidget {
  final TextEditingController passwordController;
  final bool isEmpty;
  final String labelText;
  final bool obscureText;
  final IconData obscureTextOff;
  final IconData? obscureTextOn;
  const AuthenticationTextField(
      {super.key,
      required this.passwordController,
      required this.isEmpty,
      required this.labelText,
      required this.obscureText,
      required this.obscureTextOff,
      this.obscureTextOn});

  @override
  State<AuthenticationTextField> createState() =>
      _AuthenticationTextFieldState();
}

class _AuthenticationTextFieldState extends State<AuthenticationTextField> {
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;

  late bool obscureText;

  late bool clickable;

  @override
  void initState() {
    super.initState();
    obscureText = widget.obscureText;
    clickable = widget.obscureTextOn != null;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: widget.isEmpty
                    ? Colors.red
                    : _isFocused
                        ? Colors.blue
                        : Colors.white,
                blurRadius: 10,
                spreadRadius: 2),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.passwordController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
                border: InputBorder.none,
                labelText: widget.labelText,
                labelStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        if (clickable) {
                          obscureText = !obscureText;
                        }
                      });
                    },
                    icon: Icon(obscureText
                        ? widget.obscureTextOn
                        : widget.obscureTextOff))),
            obscureText: obscureText,
          ),
        ),
      ),
    );
  }
}

class CustomHttpClient {
  static HttpClient getClient() {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            true; // Trust all certificates
    return client;
  }
}
