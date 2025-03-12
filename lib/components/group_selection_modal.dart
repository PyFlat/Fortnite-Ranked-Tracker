import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'account_search_widget.dart';

class GroupSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final Function(List<Map<String, dynamic>>) onGroupsChanged;

  const GroupSelectionModal({
    super.key,
    required this.groups,
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

  @override
  void initState() {
    selectedGroupIndex = widget.groups.indexWhere((item) => item["selected"]);
    if (selectedGroupIndex == -1) {
      selectedGroupIndex = null;
    }
    super.initState();
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
    final groupNames = widget.groups.map((element) => element["name"]).toList();
    return Container(
      key: const ValueKey('groupList'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
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
                    if (widget.groups.any((item) => item["name"].isEmpty)) {
                      widget.groups.removeWhere(
                          (item) => (item["name"] as String).isEmpty);
                    }

                    widget.groups
                        .add({"name": "", "selected": false, "members": []});
                    editingIndex = widget.groups.length - 1;
                    _editingController.text = '';
                    widget.onGroupsChanged(widget.groups);
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
      ),
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
                  widget.groups.removeWhere((item) => item["name"] == oldName);
                  widget.onGroupsChanged(widget.groups);
                  editingIndex = null;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.done, color: Colors.green),
              onPressed: () {
                final newName = _editingController.text.trim();
                setState(() {
                  if (newName == oldName) {
                    editingIndex = null;
                  } else if (widget.groups
                      .any((item) => item["name"] == newName)) {
                    return;
                  } else if (newName.isNotEmpty) {
                    widget.groups[editingIndex!]['name'] = newName;
                  } else if (newName.isEmpty) {
                    widget.groups
                        .removeWhere((item) => item["name"] == oldName);
                  }
                  editingIndex = null;
                });
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
              '$groupName (${(widget.groups[index]["members"] as List).length} members)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            if (selectedGroupIndex != null) {
              widget.groups[selectedGroupIndex!]['selected'] = false;
            }
            if (selectedGroupIndex == index) {
              selectedGroupIndex = null;
            } else {
              widget.groups[index]['selected'] = true;
              selectedGroupIndex = index;
            }
          });
          widget.onGroupsChanged(widget.groups);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  if (editingIndex != null) {
                    if (widget.groups[editingIndex!]["name"].isEmpty) {
                      widget.groups.removeAt(editingIndex!);
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
    final List members = widget.groups[memberEditingIndex!]['members'];

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
                  '${widget.groups[memberEditingIndex!]['name']} Group',
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
            onAccountSelected: (accountId, displayName, platform) {
              setState(() {
                members.add({
                  "accountId": accountId,
                  "displayName": displayName,
                  "platform": platform
                });
                widget.onGroupsChanged(widget.groups);
              });
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
                              onPressed: () {
                                setState(() {
                                  members.removeWhere((element) =>
                                      element['accountId'] ==
                                      item['accountId']);
                                  widget.onGroupsChanged(widget.groups);
                                });
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
