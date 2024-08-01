import 'package:fortnite_ranked_tracker/core/api_service.dart';
import 'package:fortnite_ranked_tracker/core/auth_provider.dart';
import 'package:fortnite_ranked_tracker/screens/graph_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/rank_service.dart';
import '../screens/home_screen.dart';
import 'package:flutter/material.dart';

import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final Talker talker;

  const MainScreen(
      {super.key, required this.authProvider, required this.talker});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Future<void>? _initializationFuture;

  List<Widget> get _widgetOptions {
    return <Widget>[
      HomeScreen(talker: widget.talker),
      GraphScreen(),
      PlaceholderScreen(title: 'Page 4'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeRankService();
  }

  Future<void> _initializeRankService() async {
    await ApiService().init(widget.talker, widget.authProvider);
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
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else {
            return Center(child: _widgetOptions.elementAt(_selectedIndex));
          }
        },
      ),
      drawer: Drawer(
        child: Column(
          children: [
            FutureBuilder<void>(
                future: _initializationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade400,
                      ),
                      child: const Row(children: [
                        CircleAvatar(
                            radius: 40, child: CircularProgressIndicator()),
                      ]),
                    );
                  }
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade400,
                    ),
                    child: Row(
                      children: [
                        FutureBuilder<String>(
                          future: RankService()
                              .getAccountAvatar(), // Call the async function here
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // Show a loading indicator while waiting
                              return const CircleAvatar(
                                  radius: 40,
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              // Handle errors
                              return const Icon(Icons.error, color: Colors.red);
                            } else if (snapshot.hasData) {
                              // Display the image once the URL is fetched
                              return CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            } else {
                              // Handle the case where there's no data
                              return const Icon(Icons.image,
                                  color: Colors.grey);
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.authProvider.displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ListTile(
                    leading:
                        const Icon(Icons.dashboard, color: Colors.blueGrey),
                    title:
                        const Text('Dashboard', style: TextStyle(fontSize: 16)),
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_up_rounded,
                        color: Colors.blueGrey),
                    title: const Text('Graph', style: TextStyle(fontSize: 16)),
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded,
                        color: Colors.blueGrey),
                    title:
                        const Text('Database', style: TextStyle(fontSize: 16)),
                    onTap: () => _onItemTapped(2),
                  ),
                  // Spacer to push the settings to the bottom
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.my_library_books_rounded,
                  color: Colors.blueGrey),
              title: const Text('Logs', style: TextStyle(fontSize: 16)),
              onTap: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TalkerScreen(talker: widget.talker)))
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: const Text('Settings', style: TextStyle(fontSize: 16)),
              onTap: () => {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()))
              },
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
