import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/database.dart';
import '../screens/database_screen.dart';
import '../screens/graph_screen.dart';
import '../screens/search_screen.dart';
import 'account_details_dialog.dart';

class UserPopupMenu extends StatelessWidget {
  final String displayName;
  final String accountId;
  final String? nickName;
  final Talker talker;
  final Function(String accountId, String newNickName)? nickNameChanged;
  const UserPopupMenu(
      {super.key,
      required this.context,
      required this.displayName,
      required this.accountId,
      required this.nickName,
      required this.talker,
      this.nickNameChanged});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (String value) {
        if (value == "show_account_details") {
          showAccountDetailsDialog(context, displayName, accountId, nickName,
              nickNameChanged: nickNameChanged);
        } else if (value == "open_user") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SearchScreen(
                      accountId: accountId,
                      displayName: displayName,
                      talker: talker,
                    )),
          );
        } else if (value == "open_database") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DatabaseScreen(account: {
                        "displayName": displayName,
                        "accountId": accountId
                      })));
        } else if (value == "open_graph") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GraphScreen(
                        account: {
                          "displayName": displayName,
                          "accountId": accountId
                        },
                        talker: talker,
                      )));
        } else if (value == "delete_user") {
          _showConfirmationDialog(context);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          buildMenuItem("Open User", const Icon(Icons.open_in_new)),
          const PopupMenuDivider(),
          buildMenuItem(
              "Show Account Details", const Icon(Icons.remove_red_eye_rounded)),
          const PopupMenuDivider(),
          buildMenuItem("Open Database", const Icon(Icons.storage_rounded)),
          buildMenuItem("Open Graph", const Icon(Icons.trending_up_rounded)),
          const PopupMenuDivider(),
          buildMenuItem("Delete User",
              Icon(Icons.delete_forever_rounded, color: Colors.red.shade400),
              textStyle: TextStyle(color: Colors.red.shade400)),
        ];
      },
    );
  }

  PopupMenuItem<String> buildMenuItem(String text, Icon icon,
      {TextStyle? textStyle}) {
    return PopupMenuItem<String>(
      value: text.toLowerCase().replaceAll(" ", "_"),
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.only(right: 8.0), child: icon),
          Text(
            text,
            style: textStyle,
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.warning_rounded,
                  color: Colors.red.shade400, size: 32.0),
              const SizedBox(width: 10),
              const Text(
                'Warning',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Are you certain you want to delete all user data?\nThis action cannot be undone.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Proceed'),
              onPressed: () async {
                await DataBase().removeAccounts([accountId]);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
