import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:fortnite_ranked_tracker/core/database.dart';
import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';
import '../core/rank_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(title: const Text("Application"), tiles: [
            SettingsTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: const Text("Purge Databases of Inactive Users"),
              onPressed: (context) {
                showDialog<List<Map<String, dynamic>>?>(
                  context: context,
                  builder: (BuildContext context) {
                    return const SelectAccountsDialog();
                  },
                ).then((selectedAccounts) {
                  if (selectedAccounts != null) {
                    List<String> accountIds = selectedAccounts
                        .map((account) => account['AccountId'] as String)
                        .toList();
                    final database = DataBase();
                    database.removeAccounts(accountIds);
                  }
                });
              },
            )
          ])
        ],
      ),
    );
  }
}

class SelectAccountsDialog extends StatefulWidget {
  const SelectAccountsDialog({super.key});

  @override
  SelectAccountsDialogState createState() => SelectAccountsDialogState();
}

class SelectAccountsDialogState extends State<SelectAccountsDialog> {
  final List<Map<String, dynamic>> _selectedAccounts = [];
  late Future<Map<String, dynamic>> _getData;

  @override
  void initState() {
    super.initState();
    _getData = _loadData();
  }

  String _searchQuery = "";

  void _toggleAccountSelection(Map<String, dynamic> account, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedAccounts.remove(account);
      } else {
        _selectedAccounts.add(account);
      }
    });
  }

  Future<Map<String, dynamic>> _loadData() async {
    final database = DataBase();
    List<Map<String, dynamic>> inactiveAccounts =
        await database.getInactiveAccounts();

    List<String> accountIds = inactiveAccounts
        .map((account) => account['AccountId'] as String)
        .toList();

    String joinedAccountIds = accountIds.join(',');

    Map<String, String> avatarURLs = {};

    if (accountIds.isNotEmpty) {
      avatarURLs = await RankService().getAccountAvatarById(joinedAccountIds);
    }

    return {
      'inactiveAccounts': inactiveAccounts,
      'avatarURLs': avatarURLs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            title: Text('Loading...'),
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load data: ${snapshot.error}'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        } else if (snapshot.hasData) {
          final inactiveAccounts =
              snapshot.data!['inactiveAccounts'] as List<Map<String, dynamic>>;
          final avatarURLs =
              snapshot.data!['avatarURLs'] as Map<String, String>;

          final filteredAccounts = inactiveAccounts
              .where((account) => (account["DisplayName"] as String)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            title: const Text(
              'Select Accounts to Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.minPositive,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = filteredAccounts[index];
                        final isSelected = _selectedAccounts.contains(account);
                        final avatarURL = avatarURLs[account["AccountId"]];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(avatarURL ??
                                  ApiService().addPathParams(Endpoints.skinIcon,
                                      {"skinId": Constants.defaultSkinId})),
                            ),
                            title: Text(
                              account["DisplayName"],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.white)
                                : const Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () =>
                                _toggleAccountSelection(account, isSelected),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            splashColor:
                                Colors.purple.shade600.withOpacity(0.3),
                            tileColor: isSelected
                                ? Colors.purple.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(_selectedAccounts);
                },
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: const Text('No data available'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      },
    );
  }
}
