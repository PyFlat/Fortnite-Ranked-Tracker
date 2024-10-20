import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
}
