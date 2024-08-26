import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final SearchController searchController;
  final Function? onChanged;
  const CustomSearchBar(
      {super.key, required this.searchController, this.onChanged});

  @override
  CustomSearchBarState createState() => CustomSearchBarState();
}

class CustomSearchBarState extends State<CustomSearchBar> {
  bool _trailingVisible = false;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.searchController,
      hintText: "Search",
      leading: const Padding(
        padding: EdgeInsets.only(left: 4.0),
        child: Icon(Icons.search_rounded),
      ),
      trailing: _trailingVisible
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  onPressed: () {
                    widget.searchController.clear();
                    setState(() {
                      _trailingVisible = false;
                    });
                    if (widget.onChanged != null) {
                      widget.onChanged!("");
                    }
                  },
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: "Clear text",
                ),
              )
            ]
          : [],
      onChanged: (value) {
        setState(() {
          _trailingVisible = value.isNotEmpty ? true : false;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
    );
  }
}
