import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';

class GraphScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const GraphScreen({super.key, required this.account});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool _clicked = false;

  double lastClickedX = 0;

  double lastClickedY = 0;

  double _lastOffsetX = 0;

  double _lastOffsetY = 0;

  double _currentOffsetX = 0;

  double _currentOffsetY = 0;

  double _maxRangeX = 30;

  double _maxRangeY = 300;

  double _displayIntervall = 1;

  double _sliderVerticalState = 0;

  double _sliderHorizontalState = 0;

  final double _maxZoom = 10;

  final double _minZoom = 0.5;

  int _dataLength = 0;

  late Future<List<dynamic>> _dataFuture;

  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dataFuture = makeData();
  }

  void _onClick(PointerEvent e) {
    lastClickedX = e.position.dx;
    lastClickedY = e.position.dy;
    _lastOffsetX = _currentOffsetX;
    _lastOffsetY = _currentOffsetY;
    _clicked = true;
  }

  Size getGraphDimensions() {
    final RenderBox renderBox =
        _key.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size;
  }

  void _onRelease(PointerEvent e) {
    _clicked = false;
  }

  void _updatePosition(PointerEvent e) {
    if (_clicked) {
      double dx = (e.position.dx - lastClickedX);
      double dy = (e.position.dy - lastClickedY);
      Size graphSize = getGraphDimensions();
      dx /= (graphSize.width / _maxRangeX);
      dy /= (graphSize.height / _maxRangeY);
      if (_currentOffsetX - dx < 0 ||
          _currentOffsetX - dx + _maxRangeX > _dataLength) {
        _onClick(e);
        setState(() {
          if (_currentOffsetX - dx < 0) {
            _currentOffsetX = 0;
            _sliderHorizontalState = 0;
          } else {
            _currentOffsetX = _dataLength - _maxRangeX;
            _sliderHorizontalState = 1;
          }
        });
        if (_currentOffsetY.abs() * 2 < _currentOffsetX.abs()) {
          return;
        }

        dx = 0;
      }
      if (_currentOffsetY + dy < 0 || _currentOffsetY + dy > 2000) {
        _onClick(e);
        setState(() {
          if (_currentOffsetY + dy < 0) {
            _currentOffsetY = 0;
            _sliderVerticalState = 0;
          } else {
            _currentOffsetY = 2000;
            _sliderVerticalState = 1;
          }
        });
        if (_currentOffsetX.abs() * 2 < _currentOffsetY.abs()) {
          return;
        }
        dy = 0;
      }
      setState(() {
        _currentOffsetX = _lastOffsetX - dx;
        _currentOffsetY = _lastOffsetY + dy;
        double newsliderstate = _currentOffsetY / 2000;
        if (newsliderstate > 1) {
          newsliderstate = 1;
        } else if (newsliderstate < 0) {
          newsliderstate = 0;
        }
        _sliderVerticalState = newsliderstate;
        newsliderstate = _currentOffsetX / (_dataLength - _maxRangeX);
        if (newsliderstate > 1) {
          newsliderstate = 1;
        } else if (newsliderstate < 0) {
          newsliderstate = 0;
        }
        _sliderHorizontalState = newsliderstate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder(
            future: _dataFuture,
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Container();
              } else if (snapshot.hasData) {
                return AspectRatio(
                  aspectRatio: 1.75,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _sliderVerticalState,
                                onChanged: (newValue) {
                                  setState(() {
                                    _sliderVerticalState = newValue;
                                    _currentOffsetY =
                                        2000 * _sliderVerticalState;
                                  });
                                },
                                min: 0,
                                max: 1,
                              ),
                            ),
                            Expanded(
                              child: Listener(
                                onPointerDown: _onClick,
                                onPointerMove: _updatePosition,
                                onPointerUp: _onRelease,
                                onPointerSignal: (event) {
                                  if (event is PointerScrollEvent) {
                                    double dx = event.scrollDelta.dx / 100;
                                    double dy = event.scrollDelta.dy / 100;
                                    if (dy < 0) {
                                      if (_displayIntervall / 1.1 < _minZoom)
                                        return;
                                      setState(() {
                                        _maxRangeY /= 1.1;
                                        _maxRangeX /= 1.1;
                                        _displayIntervall /= 1.1;
                                      });
                                    } else {
                                      if (_displayIntervall * 1.1 > _maxZoom)
                                        return;
                                      setState(() {
                                        _maxRangeY *= 1.1;
                                        _maxRangeX *= 1.1;
                                        _displayIntervall *= 1.1;
                                      });
                                    }
                                  }
                                },
                                child: LineChart(
                                  key: _key,
                                  LineChartData(
                                    lineTouchData: LineTouchData(
                                      touchSpotThreshold: 20,
                                      touchTooltipData: LineTouchTooltipData(
                                        maxContentWidth: 200,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map((touchedSpot) {
                                            final int index =
                                                touchedSpot.spotIndex;
                                            final Map<String, dynamic> data =
                                                snapshot.data![0][index];
                                            return LineTooltipItem(
                                              'Match: ${data["id"]}\n'
                                              'Rank: ${data["rank"]} ${data["rank"] == "Unreal" ? "#${data["progress"]}" : "${data["progress"]}%"}\n'
                                              'Datetime ${data["datetime"]}\n'
                                              'Daily Match: ${data["daily_match_id"]}',
                                              const TextStyle(
                                                  color: Colors.black),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    baselineX: _currentOffsetX.toDouble(),
                                    baselineY: _currentOffsetY.toDouble(),
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
                                          if (index >= 0 &&
                                              index < Constants.ranks.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16.0),
                                              child:
                                                  Text(Constants.ranks[index]),
                                            );
                                          } else if (index == 20) {
                                            return const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16.0),
                                              child: Text("#1"),
                                            );
                                          } else {
                                            return const Text("");
                                          }
                                        },
                                        showTitles: true,
                                      )),
                                      bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                        interval: _displayIntervall,
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(value.toInt().toString());
                                        },
                                      )),
                                      topTitles: const AxisTitles(
                                          axisNameSize: 50,
                                          axisNameWidget: Center(
                                              child: Text(
                                                  "Progress Over Time"))), // Optional: Hide top titles
                                    ),

                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 2),
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
                                    minX: _currentOffsetX,
                                    maxX: _currentOffsetX + _maxRangeX,
                                    minY: _currentOffsetY,
                                    maxY: _currentOffsetY + _maxRangeY,
                                    // Enable zooming and panning
                                    clipData: FlClipData.all(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: _sliderHorizontalState,
                        onChanged: (newValue) {
                          setState(() {
                            _sliderHorizontalState = newValue;
                            _currentOffsetX =
                                (_dataLength - _maxRangeX) * newValue;
                          });
                        },
                        min: 0,
                        max: 1,
                      ),
                    ],
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
        widget.account["accountId"], "chapter_5_season_3_br");

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      num yValue = data[i]["total_progress"];
      if (yValue >= 1700) {
        yValue = 1700 + (convertProgressForUnreal(yValue.toDouble()) * 300);
      }
      spots.add(FlSpot(i.toDouble(), yValue.toDouble()));
    }

    _currentOffsetY = (data[0]["total_progress"] as int).toDouble() - 10;
    _sliderVerticalState = _currentOffsetY / 2000;
    _dataLength = data.length;

    return [data, spots];
  }
}
