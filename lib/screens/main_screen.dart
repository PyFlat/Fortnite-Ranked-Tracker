import 'package:fortnite_ranked_tracker/core/auth_provider.dart';

import '../core/rank_service.dart';
import '../screens/home_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const MainScreen({super.key, required this.authProvider});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Future<void>? _initializationFuture;

  List<Widget> get _widgetOptions {
    return <Widget>[
      HomeScreen(),
      PlaceholderScreen(title: 'Page 3'),
      PlaceholderScreen(title: 'Page 4'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeRankService();
  }

  Future<void> _initializeRankService() async {
    await RankService().init(widget.authProvider);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fortnite Ranked Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.filled(
                isSelected: false,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsScreen()));
                },
                icon: const Icon(Icons.settings)),
          )
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error initializing app'));
          } else {
            return Center(child: _widgetOptions.elementAt(_selectedIndex));
          }
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.pages),
              title: Text('Page 3'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.pages),
              title: Text('Page 4'),
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('$title Content'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text('Settings Page'),
      ),
    );
  }
}
