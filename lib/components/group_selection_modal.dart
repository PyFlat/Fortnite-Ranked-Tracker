import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

import 'account_search_widget.dart';

class GroupSelectionModal extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onGroupsChanged;

  final int? selectedGroupIndex;

  const GroupSelectionModal({
    super.key,
    this.selectedGroupIndex,
    required this.onGroupsChanged,
  });

  @override
  State<GroupSelectionModal> createState() => _GroupSelectionModalState();
}

class _GroupSelectionModalState extends State<GroupSelectionModal> {
  int? memberEditingIndex;
  int? selectedGroupIndex;
  int? editingIndex;
  final TextEditingController _editingController = TextEditingController();

  List<Map<String, dynamic>> groups = [];

  late Future<void> _dataFuture;

  @override
  void initState() {
    _dataFuture = getGroups();

    selectedGroupIndex = widget.selectedGroupIndex;

    super.initState();
  }

  Future<void> getGroups() async {
    final response = await RankService().getGroups();
    if (selectedGroupIndex != null) {
      response[selectedGroupIndex!]['selected'] = true;
    }
    if (mounted) {
      setState(() {
        groups = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: memberEditingIndex == null
              ? _buildGroupListView()
              : _buildGroupMembersView(),
        ),
      ),
    );
  }

  Widget _buildGroupListView() {
    final groupNames = groups.map((element) => element["name"]).toList();
    return Container(
      key: const ValueKey('groupList'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('An error occurred.'));
            }
            return Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tournament Groups',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (groups.any((item) => item["name"].isEmpty)) {
                            groups.removeWhere(
                                (item) => (item["name"] as String).isEmpty);
                          }

                          groups.add(
                              {"name": "", "selected": false, "members": []});
                          editingIndex = groups.length - 1;
                          _editingController.text = '';
                          widget.onGroupsChanged(groups);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white54),
                const SizedBox(height: 8),
                Expanded(
                  child: groupNames.isEmpty
                      ? const Center(
                          child: Text(
                            'No groups yet.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: groupNames.length,
                          itemBuilder: (context, index) {
                            final oldName = groupNames[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: editingIndex == index
                                  ? _buildEditingTile(oldName, index)
                                  : _buildGroupTile(oldName, index),
                            );
                          },
                        ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildEditingTile(String oldName, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        title: TextField(
          controller: _editingController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter group name',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (index == selectedGroupIndex) {
                    selectedGroupIndex = null;
                  }
                  groups.removeWhere((item) => item["name"] == oldName);
                  widget.onGroupsChanged(groups);
                  editingIndex = null;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.done, color: Colors.green),
              onPressed: () async {
                final newName = _editingController.text.trim();
                final previousEditingIndex = editingIndex!;
                setState(() {
                  if (newName == oldName) {
                    editingIndex = null;
                  } else if (groups.any((item) => item["name"] == newName)) {
                    return;
                  } else if (newName.isNotEmpty) {
                    groups[editingIndex!]['name'] = newName;
                  } else if (newName.isEmpty) {
                    groups.removeWhere((item) => item["name"] == oldName);
                  }
                  editingIndex = null;
                });
                if (newName.isNotEmpty && newName != oldName) {
                  await RankService().changeGroupMetadata(newName,
                      id: groups[previousEditingIndex]['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTile(String groupName, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor:
          selectedGroupIndex == index ? Colors.pinkAccent : Colors.transparent,
      elevation: 4,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: Colors.white,
        selected: selectedGroupIndex == index,
        selectedTileColor: Colors.pinkAccent.withValues(alpha: .3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        splashColor: Colors.pinkAccent.withValues(alpha: .3),
        title: Row(
          children: [
            Text(
              '$groupName (${(groups[index]["members"] as List).length} members)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            if (selectedGroupIndex != null) {
              groups[selectedGroupIndex!]['selected'] = false;
            }
            if (selectedGroupIndex == index) {
              selectedGroupIndex = null;
            } else {
              groups[index]['selected'] = true;
              selectedGroupIndex = index;
            }
          });
          widget.onGroupsChanged(groups);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  if (editingIndex != null) {
                    if (groups[editingIndex!]["name"].isEmpty) {
                      groups.removeAt(editingIndex!);
                    }
                  }
                  editingIndex = index;
                  _editingController.text = groupName;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_right_rounded),
              onPressed: () {
                setState(() {
                  memberEditingIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMembersView() {
    final List members = groups[memberEditingIndex!]['members'];

    return Container(
      key: const ValueKey('groupMembers'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => memberEditingIndex = null),
              ),
              Expanded(
                child: Text(
                  '${groups[memberEditingIndex!]['name']} Group',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const Divider(color: Colors.white),
          const SizedBox(height: 8),
          AccountSearchWidget(
            onAccountSelected: (accountId, displayName, platform) async {
              setState(() {
                members.add({
                  "accountId": accountId,
                  "displayName": displayName,
                  "platform": platform
                });
                widget.onGroupsChanged(groups);
              });
              await RankService().updateGroup(
                accountId,
                groups[memberEditingIndex!]['id'],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: members.isEmpty
                ? const Center(
                    child: Text(
                      'No members yet.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final item = members[index];
                      // final key = members.keys.elementAt(index);
                      // final value = members[key];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: SvgPicture.asset(
                              "assets/icons/${item['platform']}.svg",
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                            title: Text(
                              item['displayName'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                setState(() {
                                  members.removeWhere((element) =>
                                      element['accountId'] ==
                                      item['accountId']);
                                  widget.onGroupsChanged(groups);
                                });

                                await RankService().updateGroup(
                                  item["accountId"],
                                  groups[memberEditingIndex!]['id'],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
