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

  const MainScreen({
    super.key,
    required this.authProvider,
    required this.talker,
    required this.dio,
  });

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final DataBase _database = DataBase();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Future<void>? _initializationFuture;

  List<Widget> get _widgetOptions {
    return <Widget>[
      HomeScreen(talker: widget.talker),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeRankService();
  }

  Future<void> _initializeRankService() async {
    await ApiService().init(widget.talker, widget.authProvider, widget.dio);
    await RankService().init(widget.talker, widget.authProvider);
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
      mutableAccount["accountAvatar"] = avatarImages[account["accountId"]];

      mutableAccount["trackedSeasons"] = await _database
          .getTrackedTableCount(mutableAccount["accountId"], limit: 1);

      updatedData.add(mutableAccount);
    }).toList();

    await Future.wait(futures);

    updatedData.sort((a, b) => a['displayName'].compareTo(b['displayName']));

    return updatedData;
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
                          StreamBuilder(
                            stream: RankService().getAccountAvatar(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircleAvatar(
                                    radius: 40,
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Icon(Icons.error,
                                    color: Colors.red);
                              } else if (snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(snapshot.data!),
                                );
                              } else {
                                return const Icon(Icons.image,
                                    color: Colors.grey);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.authProvider.displayName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                StreamBuilder(
                                  stream: RankService().getServerStatusStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            color: snapshot.data!
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            "Fortnite is ${snapshot.data! ? "online" : "offline"}.",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                )
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
                        accountsFuture: _getAccounts(),
                        scaffoldKey: scaffoldKey,
                        talker: widget.talker),
                    AccountListTile(
                        name: 'Graph',
                        icon: const Icon(Icons.trending_up_rounded,
                            color: Colors.blueGrey),
                        accountsFuture: _getAccounts(),
                        scaffoldKey: scaffoldKey,
                        talker: widget.talker),
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
                          builder: (context) =>
                              TalkerScreen(talker: widget.talker)));
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
  final Talker talker;

  AccountListTile(
      {super.key,
      required this.name,
      required this.icon,
      required this.accountsFuture,
      required this.scaffoldKey,
      required this.talker});

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
                              builder: (context) =>
                                  GraphScreen(talker: talker)));
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(ApiService().addPathParams(
                          Endpoints.skinIcon,
                          {"skinId": Constants.defaultSkinId})),
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
                                : GraphScreen(account: account, talker: talker);
                          }),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(account["accountAvatar"]),
                      ),
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
