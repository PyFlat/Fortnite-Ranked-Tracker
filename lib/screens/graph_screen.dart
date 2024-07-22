import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

class GraphScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
            future: makeData(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                return LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        maxContentWidth: 200,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final int index = touchedSpot.spotIndex;
                            final Map<String, dynamic> data =
                                snapshot.data![0][index];
                            return LineTooltipItem(
                              'Match: ${data["id"]}\n'
                              'Rank: ${data["rank"]} ${data["progress"]}%\n'
                              'Datetime ${data["datetime"]}\n'
                              'Daily Match: ${data["daily_match_id"]}',
                              const TextStyle(color: Colors.black),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    baselineX: 0,
                    baselineY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        dotData: FlDotData(show: false),
                        spots: snapshot.data![1],
                        isCurved: true,
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          axisNameWidget: SizedBox(
                        width: 40,
                      )), // Hide left Y-axis titles
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                        reservedSize: 125,
                        interval: 100,
                        getTitlesWidget: (value, meta) {
                          int index = (value / 100).round();
                          if (index >= 0 && index < Constants.ranks.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(Constants.ranks[index]),
                            );
                          } else if (index == 20) {
                            return const Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text("#1"),
                            );
                          } else {
                            return const Text("");
                          }
                        },
                        showTitles: true,
                      )),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              interval: 1, showTitles: true, reservedSize: 40)),
                      topTitles: const AxisTitles(
                          axisNameSize: 50,
                          axisNameWidget: Center(
                              child: Text(
                                  "Progress Over Time"))), // Optional: Hide top titles
                    ),

                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: const Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    minX: 0,
                    maxX: 50,
                    minY: 0,
                    maxY: 2000,
                    // Enable zooming and panning
                    clipData: FlClipData.all(),
                  ),
                );
              } else {
                return Container();
              }
            }),
      ),
    );
  }

  Future<List<dynamic>> makeData() async {
    final data = await RankService().getRankedDataBySeason(
        "49a809c144844feea10b90b60b27d8bc", "chapter_5_season_3_br");

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      num yValue = data[i]["total_progress"];
      spots.add(FlSpot(i.toDouble(), yValue.toDouble()));
    }
    return [data, spots];
  }
}
