import 'package:dio/dio.dart';
import 'package:fortnite_ranked_tracker/core/api_service.dart';
import 'package:fortnite_ranked_tracker/core/auth_provider.dart';
import 'package:fortnite_ranked_tracker/screens/database_screen.dart';
import 'package:fortnite_ranked_tracker/screens/graph_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/database.dart';
import '../core/rank_service.dart';
import '../screens/home_screen.dart';
import 'package:flutter/material.dart';

import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final Talker talker;
  final Dio dio;

  const MainScreen(
      {super.key,
      required this.authProvider,
      required this.talker,
      required this.dio});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DataBase _database = DataBase();
  final SearchController _searchController = SearchController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Future<void>? _initializationFuture;

  List<Widget> get _widgetOptions {
    return <Widget>[
      HomeScreen(talker: widget.talker),
      GraphScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeRankService();
  }

  Future<void> _initializeRankService() async {
    await ApiService().init(widget.talker, widget.authProvider, widget.dio);
    await RankService().init(widget.authProvider);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Future<List<Map<String, dynamic>>> _getAccounts() async {
    List<Map<String, dynamic>> data = await _database.getFilteredAccountData();
    Map<String, String> avatarImages = {};
    List<String> accountIds =
        data.map((item) => item['accountId'] as String).toList();

    String joinedAccountIds = accountIds.join(',');

    if (accountIds.isNotEmpty) {
      avatarImages = await RankService().getAccountAvatarById(joinedAccountIds);
    }

    List<Map<String, dynamic>> updatedData = [];

    List<Future<void>> futures = data.map((account) async {
      Map<String, dynamic> mutableAccount = Map.from(account);
      String? avatarURL = avatarImages[account["accountId"]];
      mutableAccount["accountAvatar"] = avatarURL != null
          ? avatarImages[account["accountId"]]
          : ApiService().addPathParams(
              Endpoints.skinIcon, {"skinId": Constants.defaultSkinId});

      mutableAccount["trackedSeasons"] =
          await _database.getTableCount(mutableAccount["accountId"]);

      updatedData.add(mutableAccount);
    }).toList();

    await Future.wait(futures);

    return updatedData;
  }

  List<Map<String, dynamic>> _filterAccounts(
      String query, List<Map<String, dynamic>> accounts) {
    if (query.isEmpty) {
      return accounts;
    }
    return accounts.where((account) {
      final displayName = (account['displayName'] as String).toLowerCase();
      return displayName.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TalkerWrapper(
      talker: widget.talker,
      options: const TalkerWrapperOptions(
        enableErrorAlerts: true,
        enableExceptionAlerts: true,
      ),
      child: Scaffold(
        key: scaffoldKey,
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
                                return const Icon(Icons.error,
                                    color: Colors.red);
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
                      title: const Text('Dashboard',
                          style: TextStyle(fontSize: 16)),
                      onTap: () => _onItemTapped(0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.trending_up_rounded,
                          color: Colors.blueGrey),
                      title:
                          const Text('Graph', style: TextStyle(fontSize: 16)),
                      onTap: () => _onItemTapped(1),
                    ),
                    _buildDatabaseListTile()
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
      ),
    );
  }

  FutureBuilder<List<Map<String, dynamic>>> _buildDatabaseListTile() {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              leading:
                  const Icon(Icons.storage_rounded, color: Colors.blueGrey),
              title: const Text('Database', style: TextStyle(fontSize: 16)),
              onTap: () {},
            );
          }
          return SearchAnchor(
            searchController: _searchController,
            viewLeading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                scaffoldKey.currentState!.closeDrawer();

                setState(() {
                  _searchController.closeView("");
                });
              },
            ),
            isFullScreen: true,
            builder: (BuildContext context, SearchController controller) {
              return ListTile(
                leading:
                    const Icon(Icons.storage_rounded, color: Colors.blueGrey),
                title: const Text('Database', style: TextStyle(fontSize: 16)),
                onTap: () {
                  controller.openView();
                },
              );
            },
            suggestionsBuilder: (context, controller) {
              final suggestions =
                  _filterAccounts(controller.value.text, snapshot.data!);
              return suggestions.isEmpty
                  ? [
                      const ListTile(
                          title: Text(
                        'No results found',
                        textAlign: TextAlign.center,
                      ))
                    ]
                  : suggestions.map((account) {
                      return IntrinsicWidth(
                        child: Column(children: [
                          ListTile(
                            onTap: () {
                              print(account["accountId"]);
                              // scaffoldKey.currentState!.closeDrawer();

                              // setState(() {
                              //   controller.closeView("");
                              // });
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DatabaseScreen(account: account)));
                            },
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(account["accountAvatar"]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert_rounded),
                              onPressed: () {},
                            ),
                            title: Text(account['displayName'] ?? ''),
                            subtitle: Text(
                                "Tracked seasons: ${account["trackedSeasons"]}"),
                          ),
                          const Divider(
                            height: 2,
                          )
                        ]),
                      );
                    }).toList();
            },
          );
        });
  }
}
