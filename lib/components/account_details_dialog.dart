import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/database.dart';
import '../core/rank_service.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _nickNameController;
  bool _showCheckmarkName = false;
  bool _showCheckmarkId = false;

  bool _editNickName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accountName);
    _idController = TextEditingController(text: widget.accountId);
    _nickNameController = TextEditingController(text: widget.nickName);

    if (widget.nickName != null) {
      _editNickName = true;
    } else {
      _checkPlayerExisting();
    }
  }

  Future<void> _checkPlayerExisting() async {
    _editNickName = await DataBase().getPlayerIsExisiting(widget.accountId);
    setState(() {});
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (type == 'name') {
        _showCheckmarkName = true;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showCheckmarkName = false;
            });
          }
        });
      } else if (type == 'id') {
        _showCheckmarkId = true;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showCheckmarkId = false;
            });
          }
        });
      }
    });
  }

  void _updateNickName() async {
    if (widget.nickNameChanged != null) {
      widget.nickNameChanged!(widget.accountId, _nickNameController.text);
    }
    DataBase database = DataBase();
    await database.updatePlayerNickName(
        widget.accountId, _nickNameController.text);

    RankService().emitDataRefresh();
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      readOnly: true,
                      controller: _nameController,
                      enableInteractiveSelection: false,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: "Display Name",
                        enabledBorder: _getInputBorder(),
                        border: _getInputBorder(),
                        focusedBorder: _getInputBorder(),
                        suffixIcon: _showCheckmarkName
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  _copyToClipboard(widget.accountName, 'name');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      readOnly: true,
                      controller: _idController,
                      enableInteractiveSelection: false,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: "Account Id",
                        enabledBorder: _getInputBorder(),
                        border: _getInputBorder(),
                        focusedBorder: _getInputBorder(),
                        suffixIcon: _showCheckmarkId
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  _copyToClipboard(widget.accountId, 'id');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
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
      ),
      actions: [
        TextButton(
          onPressed: () {
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
