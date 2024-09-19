import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/tournament_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../components/tournament_info_container.dart';

class TournamentScreen extends StatefulWidget {
  final Talker talker;
  const TournamentScreen({super.key, required this.talker});

  @override
  TournamentScreenState createState() => TournamentScreenState();
}

class TournamentScreenState extends State<TournamentScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TournamentDataProvider>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dataProvider = Provider.of<TournamentDataProvider>(context);

    return Scaffold(
        body: dataProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    dataProvider.fetchData();
                  },
                  child: const Icon(Icons.refresh_rounded),
                ),
                body: SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      children:
                          dataProvider.data.map((Map<String, dynamic> item) {
                        return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TournamentInfoContainer(
                              talker: widget.talker,
                              item: item,
                            ));
                      }).toList(),
                    ),
                  ),
                ),
              ));
  }

  @override
  bool get wantKeepAlive => true;
}
