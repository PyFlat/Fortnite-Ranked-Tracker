import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';
import 'package:fortnite_ranked_tracker/core/avatar_manager.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/core/socket_service.dart';

class AvatarDialog extends StatefulWidget {
  final String accountId;
  const AvatarDialog({super.key, required this.accountId});

  @override
  AvatarDialogState createState() => AvatarDialogState();
}

class AvatarDialogState extends State<AvatarDialog> {
  List<String> avatars = [];
  List<String> filteredAvatars = [];
  String searchQuery = '';
  String? selectedAvatar;
  final SearchController _searchController = SearchController();
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    filteredAvatars = avatars;
    _future = loadAvatars();
  }

  Future<void> loadAvatars() async {
    avatars = await AvatarManager().getAllAvatars();
    selectedAvatar = AvatarManager().getAvatar(widget.accountId);
    avatars.sort(
      (a, b) {
        String nameA = a
            .replaceAll("assets/avatar-images/", "")
            .replaceAll(".png", "")
            .toLowerCase();
        String nameB = b
            .replaceAll("assets/avatar-images/", "")
            .replaceAll(".png", "")
            .toLowerCase();
        return nameA.compareTo(nameB);
      },
    );
    setState(() {
      filteredAvatars = avatars;
    });
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredAvatars = avatars.where((avatar) {
        String name = avatar
            .replaceAll("assets/avatar-images/", "")
            .replaceAll(".png", "");
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        spacing: 8,
        children: [
          Expanded(
            child: CustomSearchBar(
                searchController: _searchController,
                onChanged: updateSearchQuery),
          ),
          IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              iconSize: 35,
              tooltip: "Cancel",
              icon: Icon(
                Icons.close,
                color: Colors.red,
              )),
          IconButton(
              onPressed: () {
                Navigator.of(context).pop(selectedAvatar);
              },
              iconSize: 35,
              tooltip: "Confirm",
              icon: Icon(
                Icons.check,
                color: Colors.green,
              ))
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(),
          FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading avatars');
                } else {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 100,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: filteredAvatars.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          bool isSelected = selectedAvatar == 'random';
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAvatar = 'random';
                              });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isSelected ? Colors.green : Colors.red,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              elevation: isSelected ? 8.0 : 2.0,
                              child: Center(
                                child: Icon(
                                  Icons.shuffle,
                                  size: 48,
                                  color: isSelected ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        }
                        String avatar = filteredAvatars[index - 1];
                        bool isSelected = avatar == selectedAvatar;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAvatar = avatar;
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: isSelected ? 8.0 : 2.0,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      isSelected
                                          ? Colors.black.withValues(alpha: .5)
                                          : Colors.transparent,
                                      BlendMode.darken,
                                    ),
                                    child: Image.asset(
                                      avatar,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 48,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              }),
        ],
      ),
    );
  }
}

Future<void> showAvatarDialog(BuildContext context, String accountId) async {
  final selectedAvatar = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AvatarDialog(
        accountId: accountId,
      );
    },
  );

  if (selectedAvatar != null) {
    await RankService().setAccountAvatar(accountId, selectedAvatar);
    AvatarManager().setAvatar(accountId, selectedAvatar);
    SocketService().sendDataChanged();
    RankService().emitDataRefresh();
  }
}
