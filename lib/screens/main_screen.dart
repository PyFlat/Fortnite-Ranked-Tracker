import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/avatar_manager.dart';
import '../core/rank_service.dart';
import '../core/socket_service.dart';
import '../core/talker_service.dart';
import 'package:flutter/material.dart';

import 'database_screen.dart';
import 'graph_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'tournament_screen.dart';

class MainScreen extends StatefulWidget {
  final Dio dio;

  const MainScreen({
    super.key,
    required this.dio,
  });

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Future<void>? _initializationFuture;
  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeRankService();
    _widgetOptions = [HomeScreen(), TournamentScreen()];
  }

  Future<void> _initializeRankService() async {
    SocketService().connectToSocket();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return TalkerWrapper(
      talker: talker,
      options: const TalkerWrapperOptions(
        enableErrorAlerts: true,
        enableExceptionAlerts: true,
      ),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Fortnite Ranked Tracker'),
          actions: [
            Row(
              spacing: 5,
              children: [
                Text(
                  "Connected",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                StreamBuilder(
                    stream: SocketService().connectedStatus,
                    builder: (context, snapshot) {
                      return Icon(Icons.circle,
                          color: snapshot.hasData && snapshot.data as bool
                              ? Colors.green
                              : Colors.red);
                    }),
                SizedBox(width: 15)
              ],
            )
          ],
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
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(
                                AvatarManager().getAvatar("default")),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Johannes",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // StreamBuilder(
                                //   stream: RankService().getServerStatusStream(),
                                //   builder: (context, snapshot) {
                                //     if (snapshot.hasData) {
                                //       return Row(
                                //         mainAxisAlignment:
                                //             MainAxisAlignment.center,
                                //         children: [
                                //           Icon(
                                //             Icons.circle,
                                //             color: snapshot.data!
                                //                 ? Colors.green
                                //                 : Colors.red,
                                //           ),
                                //           const SizedBox(
                                //             width: 8,
                                //           ),
                                //           Text(
                                //             "Fortnite is ${snapshot.data! ? "online" : "offline"}.",
                                //             textAlign: TextAlign.center,
                                //             style: const TextStyle(
                                //               color: Colors.grey,
                                //               fontSize: 16,
                                //             ),
                                //           ),
                                //         ],
                                //       );
                                //     }
                                //     return const SizedBox.shrink();
                                //   },
                                // )
                              ],
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
                    AccountListTile(
                        name: 'Database',
                        icon: const Icon(Icons.storage_rounded,
                            color: Colors.blueGrey),
                        accountsFuture: RankService().getAccountsWithSeasons(),
                        scaffoldKey: scaffoldKey),
                    AccountListTile(
                        name: 'Graph',
                        icon: const Icon(Icons.trending_up_rounded,
                            color: Colors.blueGrey),
                        accountsFuture:
                            RankService().getAccountsWithSeasons(limit: 6),
                        scaffoldKey: scaffoldKey),
                    ListTile(
                      leading: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.blueGrey,
                      ),
                      title: const Text("Tournaments",
                          style: TextStyle(fontSize: 16)),
                      onTap: () => _onItemTapped(1),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.my_library_books_rounded,
                    color: Colors.blueGrey),
                title: const Text('Logs', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TalkerScreen(talker: talker)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blueGrey),
                title: const Text('Settings', style: TextStyle(fontSize: 16)),
                onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()))
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountListTile extends StatelessWidget {
  final String name;
  final Icon icon;
  final Future<List<Map<String, dynamic>>> accountsFuture;
  final SearchController searchController = SearchController();
  final GlobalKey<ScaffoldState> scaffoldKey;

  AccountListTile(
      {super.key,
      required this.name,
      required this.icon,
      required this.accountsFuture,
      required this.scaffoldKey});

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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: icon,
            title: Text(name, style: const TextStyle(fontSize: 16)),
            onTap: () {},
          );
        }

        final List<Map<String, dynamic>>? accounts = snapshot.data;

        return SearchAnchor(
          searchController: searchController,
          viewLeading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              scaffoldKey.currentState!.closeDrawer();
              searchController.closeView("");
            },
          ),
          isFullScreen: true,
          builder: (BuildContext context, SearchController controller) {
            return ListTile(
              leading: icon,
              title: Text(name, style: const TextStyle(fontSize: 16)),
              onTap: () {
                controller.openView();
              },
            );
          },
          suggestionsBuilder: (context, controller) {
            final suggestions =
                _filterAccounts(controller.value.text, accounts ?? []);
            return [
              if (suggestions.isEmpty)
                const ListTile(
                  title: Text(
                    'No results found',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (name != "Database")
                Column(children: [
                  ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GraphScreen()));
                    },
                    leading: CircleAvatar(
                      backgroundImage:
                          AssetImage(AvatarManager().getAvatar("default")),
                    ),
                    title: const Text("[All Users]"),
                    subtitle: Text(
                        "All tracked seasons: ${suggestions.map((element) => element["trackedSeasons"]).toList().reduce((a, b) => a + b)}"),
                  ),
                  const Divider(height: 2),
                ]),
              ...suggestions.map((account) {
                return IntrinsicWidth(
                  child: Column(children: [
                    ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return name == "Database"
                                ? DatabaseScreen(account: account)
                                : GraphScreen(
                                    account: account,
                                  );
                          }),
                        );
                      },
                      leading: CircleAvatar(
                          backgroundImage:
                              AssetImage(account["accountAvatar"])),
                      title: Text(account['displayName'] ?? ''),
                      subtitle:
                          Text("Tracked seasons: ${account["trackedSeasons"]}"),
                    ),
                    const Divider(height: 2),
                  ]),
                );
              }),
            ];
          },
        );
      },
    );
  }
}
