import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../core/rank_service.dart';
import '../core/socket_service.dart';
import 'search_card.dart';

class AccountDetailsDialog extends StatefulWidget {
  final String accountName;
  final String accountId;
  final String? nickName;
  final GlobalKey? searchCardKey;
  final Function(String accountId, String newNickName)? nickNameChanged;
  const AccountDetailsDialog(
      {super.key,
      required this.accountName,
      required this.accountId,
      this.nickName,
      this.searchCardKey,
      this.nickNameChanged});

  @override
  State<AccountDetailsDialog> createState() => _AccountDetailsDialogState();
}

class _AccountDetailsDialogState extends State<AccountDetailsDialog> {
  late TextEditingController _nickNameController;
  late Future<Map<String, dynamic>> _displayNamesFuture;

  bool _editNickName = false;

  @override
  void initState() {
    super.initState();
    _nickNameController = TextEditingController(text: widget.nickName);

    _displayNamesFuture = _getAllDisplayNames();

    if (widget.nickName != null) {
      _editNickName = true;
    } else {
      _checkPlayerExisting();
    }
  }

  Future<void> _checkPlayerExisting() async {
    _editNickName = await RankService().getPlayerExisting(widget.accountId);
    setState(() {});
  }

  Future<Map<String, dynamic>> _getAllDisplayNames() async {
    try {
      Map<String, dynamic> accountMap = (await RankService().searchByQuery(
              widget.accountId,
              onlyAccountId: true,
              returnAll: true))
          .first;

      Set seenDisplayNames = {};

      accountMap.removeWhere((key, value) {
        if (key == "accountId") return true;
        String displayName = value['displayName']!;
        if (seenDisplayNames.contains(displayName)) {
          return true;
        } else {
          seenDisplayNames.add(displayName);
          return false;
        }
      });
      return accountMap;
    } catch (error) {
      print(error);

      return {};
    }
  }

  void _updateNickName() async {
    if (widget.nickNameChanged != null) {
      widget.nickNameChanged!(widget.accountId, _nickNameController.text);
    }
    await RankService()
        .setPlayerNickName(widget.accountId, _nickNameController.text);

    if (widget.searchCardKey != null &&
        widget.searchCardKey!.currentState != null) {
      (widget.searchCardKey!.currentState! as SearchCardState).refresh();
    }
  }

  OutlineInputBorder _getInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(
        color: Colors.deepPurple.shade400,
        width: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      titlePadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text(
        'Account Details',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      content: FutureBuilder(
          future: _displayNamesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              print(snapshot.error);
            }
            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...snapshot.data!.values.map(
                    (value) {
                      return DisplayNameRow(
                        text: value["displayName"],
                        accountType: value["platform"],
                        inputBorder: _getInputBorder(),
                      );
                    },
                  ),
                  DisplayNameRow(
                    text: widget.accountId,
                    inputBorder: _getInputBorder(),
                    labelText: "Account Id",
                  ),
                  if (_editNickName)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                readOnly: false,
                                controller: _nickNameController,
                                enableInteractiveSelection: true,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.top,
                                onChanged: (value) {
                                  _updateNickName();
                                },
                                decoration: InputDecoration(
                                  labelText: "Nickname",
                                  enabledBorder: _getInputBorder(),
                                  border: _getInputBorder(),
                                  focusedBorder: _getInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
      actions: [
        TextButton(
          onPressed: () {
            SocketService().sendDataChanged();
            RankService().emitDataRefresh();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

void showAccountDetailsDialog(BuildContext context, String accountName,
    String accountId, String? nickName,
    {GlobalKey? searchCardKey,
    Function(String accountId, String newNickName)? nickNameChanged}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AccountDetailsDialog(
          accountName: accountName,
          accountId: accountId,
          nickName: nickName,
          searchCardKey: searchCardKey,
          nickNameChanged: nickNameChanged);
    },
  );
}

class DisplayNameRow extends StatefulWidget {
  final String text;
  final String? accountType;
  final String? labelText;
  final OutlineInputBorder inputBorder;

  const DisplayNameRow(
      {super.key,
      required this.text,
      this.accountType,
      this.labelText,
      required this.inputBorder});

  @override
  State<DisplayNameRow> createState() => _DisplayNameRowState();
}

class _DisplayNameRowState extends State<DisplayNameRow> {
  late TextEditingController nameController;
  @override
  void initState() {
    nameController = TextEditingController(text: widget.text);
    super.initState();
  }

  bool showCheckmark = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  readOnly: true,
                  controller: nameController,
                  enableInteractiveSelection: false,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    enabledBorder: widget.inputBorder,
                    border: widget.inputBorder,
                    focusedBorder: widget.inputBorder,
                    prefixIcon: widget.accountType != null
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              "assets/icons/${widget.accountType}.svg",
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                          )
                        : null,
                    suffixIcon: showCheckmark
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.text));
                              setState(() {
                                showCheckmark = true;
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (mounted) {
                                    setState(() {
                                      showCheckmark = false;
                                    });
                                  }
                                });
                              });
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
