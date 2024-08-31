import 'package:flutter/material.dart';

class HomePageEditSheet extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const HomePageEditSheet({super.key, required this.data});

  @override
  HomePageEditSheetState createState() => HomePageEditSheetState();
}

class HomePageEditSheetState extends State<HomePageEditSheet> {
  late List<Map<String, dynamic>> data;
  bool trailingVisible = false;
  String searchQuery = "";
  final GlobalKey editButtonKey = GlobalKey();
  int sortBy = -1;

  @override
  void initState() {
    super.initState();
    data = widget.data;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = data.removeAt(oldIndex);
      data.insert(newIndex, item);
      sortBy = -1;
      _rebuildPositions();
    });
  }

  void _rebuildPositions() {
    for (int i = 0; i < data.length; i++) {
      data[i]['Position'] = i;
    }
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems() {
    const options = [
      'Name Alphabet',
      'Nickname Alphabet',
      'Visible',
      'Highest Rank (BR)',
      'Highest Rank (ZB)',
      'Highest Rank (RR)',
    ];

    return options.map((String value) {
      return PopupMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  void _handleSort(String? key) {
    if (key == null) return;

    setState(() {
      sortBy = -1;
      switch (key) {
        case 'Name Alphabet':
          _sortDataByField("DisplayName");
          break;
        case 'Nickname Alphabet':
          _sortDataByField("NickName");
          break;
        case 'Visible':
          _sortDataByField("Visible");
          break;
        case 'Highest Rank (BR)':
          _sortDataByField("Battle Royale.TotalProgress");
          sortBy = 0;
          break;
        case 'Highest Rank (ZB)':
          _sortDataByField("Zero Build.TotalProgress");
          sortBy = 1;
          break;
        case 'Highest Rank (RR)':
          _sortDataByField("Rocket Racing.TotalProgress");
          sortBy = 2;
          break;
        default:
          break;
      }
    });

    _rebuildPositions();
  }

  void _sortDataByField(String field) {
    data.sort((a, b) {
      final aValue = _getValue(a, field);
      final bValue = _getValue(b, field);

      if (aValue == null && bValue == null) {
        return 0;
      } else if (aValue == null) {
        return 1;
      } else if (bValue == null) {
        return -1;
      }

      if (aValue is String && bValue is String) {
        return aValue.compareTo(bValue);
      } else if (aValue is int && bValue is int) {
        return bValue.compareTo(aValue);
      } else if (aValue is double && bValue is double) {
        return aValue.compareTo(bValue);
      } else {
        throw ArgumentError('Unsupported field type for sorting');
      }
    });
  }

  dynamic _getValue(Map<String, dynamic> item, String field) {
    final parts = field.split('.');
    dynamic value = item;

    for (var part in parts) {
      if (value is Map && value.containsKey(part)) {
        value = value[part] ?? 0;
      } else {
        return null;
      }
    }

    return value;
  }

  String? getTrackedText(Map<String, dynamic> item, String key) {
    if (item.containsKey(key)) {
      var data = item[key];
      if (data == null) return null;

      String rank = data["Rank"] ?? "";
      String progressionText = data["RankProgressionText"] ?? "";
      return progressionText.isEmpty ? "Unranked" : "$rank $progressionText";
    } else {
      return null;
    }
  }

  String? getTrackedTextBasedOnSort(int sortBy, Map<String, dynamic> item) {
    if (sortBy > 0) {
      if (sortBy > 1) {
        return getTrackedText(item, "Rocket Racing");
      } else {
        return getTrackedText(item, "Zero Build");
      }
    } else {
      return getTrackedText(item, "Battle Royale");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredItems = data.where((item) {
      String displayName = item["DisplayName"] ?? "";
      return displayName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'Manage Cards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: (String newValue) {
                    _handleSort(newValue);
                  },
                  itemBuilder: (BuildContext context) {
                    return _buildPopupMenuItems();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () async {
                    Navigator.of(context).pop(data);
                  },
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: _onReorder,
            buildDefaultDragHandles: false,
            children: List.generate(filteredItems.length, (index) {
              final item = filteredItems[index];

              Icon visibilityIcon() {
                return Icon(
                  item["Visible"] == 1
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: item["Visible"] == 1 ? null : Colors.redAccent,
                );
              }

              final trackedText = (sortBy >= 0)
                  ? getTrackedTextBasedOnSort(sortBy, item)
                  : null;
              final displayText =
                  '${item["NickName"] ?? item["DisplayName"]}${trackedText != null ? " ($trackedText)" : ""}';

              return ListTile(
                key: ValueKey(index),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(item["AccountAvatar"]),
                ),
                title: Text(
                  displayText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle:
                    item["NickName"] != null ? Text(item["DisplayName"]) : null,
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: visibilityIcon(),
                      onPressed: () {
                        setState(() {
                          item["Visible"] = item["Visible"] == 1 ? 0 : 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}