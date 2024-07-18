import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MyCard extends StatefulWidget {
  final Map<dynamic, dynamic> item;

  const MyCard({super.key, required this.item});

  @override
  MyCardState createState() => MyCardState();
}

class MyCardState extends State<MyCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.deepPurple,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTabController(
        length: 3, // Number of tabs (br, zb, rr)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                widget.item["DisplayName"] ?? "NAME",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(
                  child: Text(
                    "Battle Royale",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Zero Build",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Rocket Racing",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: buildContentWidgets(widget.item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildContentWidgets(Map<dynamic, dynamic> item) {
    List<Widget> widgets = [];

    // Define a function to add widgets conditionally
    void addWidget(String key, String displayName) {
      if (item.containsKey(key)) {
        widgets.add(_buildContent(item[key]));
      } else {
        widgets.add(Center(
            child: Text(
          'Tracking for `$displayName` is not active!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        )));
      }
    }

    // Add widgets for each item key
    addWidget("Battle Royale", "Battle Royale");
    addWidget("Zero Build", "Zero Build");
    addWidget("Rocket Racing", "Rocket Racing");

    return widgets;
  }

  Widget _buildContent(Map item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 6,
          percent: 0.69,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Colors.deepPurple,
          header: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "${item["LastChanged"]}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Daily Matches: ${item["DailyMatches"]}"),
          ),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item["RankProgression"] ?? "69%"),
              Text(
                "${item["LastProgress"]}",
                style: const TextStyle(color: Colors.grey),
              )
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ranked-images/${item["Rank"]?.toLowerCase().replaceAll(" ", "")}.png',
              width: 75,
              height: 75,
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              "${item["Rank"]}",
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
