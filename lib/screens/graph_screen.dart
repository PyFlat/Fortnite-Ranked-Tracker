import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/individual_page_header.dart';

import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/core/season_service.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../components/season_selector.dart';
import 'dart:math';

class GraphScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const GraphScreen({super.key, required this.account});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final SeasonService _seasonService = SeasonService();

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

  double _sliderVerticalStateMovment = 0;

  double _sliderVerticalStateZoom = 0.5;
  double _sliderHorizontalState = 0;

  int _dataLength = 0;

  late Future<List<dynamic>> _dataFuture;

  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    zoom(0.5);
  }

  void _resetMovement() {
    setState(() {
      zoom(0);
      _sliderHorizontalState = 0;
      _sliderVerticalStateMovment = 0;
      _displayIntervall = 1;
      _maxRangeX = 30;
      _maxRangeY = 300;
      _currentOffsetX = 0;
      _currentOffsetY = 0;
      makeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seasonService.getCurrentSeason() == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSeasonBottomSheet();
      });
    }
  }

  void _openSeasonBottomSheet() {
    SeasonSelector(
      seasonService: _seasonService,
      accountId: widget.account["accountId"],
      onSeasonSelected: _refreshData,
    ).openSeasonBottomSheet(context);
  }

  void _refreshData() {
    if (_seasonService.getCurrentSeason() != null) {
      setState(() {
        _dataFuture = makeData();
      });
    }
  }

  void zoom(double newValue) {
    setState(() {
      _sliderVerticalStateZoom = newValue;
      double v = 0;
      if (newValue < 0) {
        v = pow(2, newValue).toDouble();
      } else {
        v = pow(10, newValue).toDouble();
      }
      _maxRangeX = 30 * v;
      _maxRangeY = 300 * v;
      _displayIntervall = v;

      if (_dataLength - _currentOffsetX < _maxRangeX) {
        _currentOffsetX = _dataLength - _maxRangeX;
        _sliderHorizontalState = 1;
      }
      panic();
    });
  }

  void _onClick(PointerEvent e) {
    lastClickedX = e.position.dx;
    lastClickedY = e.position.dy;
    _lastOffsetX = _currentOffsetX;
    _lastOffsetY = _currentOffsetY;
    _clicked = true;
    panic();
  }

  Size getGraphDimensions() {
    final RenderBox renderBox =
        _key.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size;
  }

  void _onRelease(PointerEvent e) {
    _clicked = false;
    panic();
  }

  void _updatePosition(PointerEvent e) {
    if (_clicked) {
      double dx = (e.position.dx - lastClickedX);
      double dy = (e.position.dy - lastClickedY);
      if (_dataLength <= _maxRangeX) {
        setState(() {
          _currentOffsetX = 0;
          _sliderHorizontalState = 0;
        });
        dx = 0;
      }
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
            panic();
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
            _sliderVerticalStateMovment = 0;
          } else {
            _currentOffsetY = 2000;
            _sliderVerticalStateMovment = 1;
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
        _sliderVerticalStateMovment = newsliderstate;
        newsliderstate = _currentOffsetX / (_dataLength - _maxRangeX);
        if (newsliderstate > 1) {
          newsliderstate = 1;
        } else if (newsliderstate < 0) {
          newsliderstate = 0;
        }
        _sliderHorizontalState = newsliderstate;
      });
    }
    panic();
  }

  void panic() {
    if (_dataLength <= _maxRangeX) {
      setState(() {
        _currentOffsetX = 0;
        _sliderHorizontalState = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph of ${widget.account["displayName"]}"),
      ),
      body: Column(
        children: [
          IndividualPageHeader(
              seasonService: _seasonService,
              accountId: widget.account["accountId"],
              onSeasonSelected: _refreshData),
          SizedBox(
            height: 30,
          ),
          Expanded(
            child: _seasonService.getCurrentSeason() == null
                ? const Center(child: Text("Please select a season"))
                : FutureBuilder(
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
                                        value: _sliderVerticalStateMovment,
                                        onChanged: (newValue) {
                                          setState(() {
                                            _sliderVerticalStateMovment =
                                                newValue;
                                            _currentOffsetY = 2000 *
                                                _sliderVerticalStateMovment;
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
                                            double delta =
                                                event.scrollDelta.dy / 2000;
                                            if (_sliderVerticalStateZoom +
                                                    delta >
                                                1) {
                                              delta = 0;
                                            } else if (_sliderVerticalStateZoom +
                                                    delta <
                                                -1) {
                                              delta = 0;
                                            }
                                            zoom(_sliderVerticalStateZoom +
                                                delta);
                                          }
                                        },
                                        child: LineChart(
                                          key: _key,
                                          LineChartData(
                                            lineTouchData: LineTouchData(
                                              touchSpotThreshold: 20,
                                              touchTooltipData:
                                                  LineTouchTooltipData(
                                                maxContentWidth: 200,
                                                getTooltipItems:
                                                    (touchedSpots) {
                                                  return touchedSpots
                                                      .map((touchedSpot) {
                                                    final int index =
                                                        touchedSpot.spotIndex;
                                                    final Map<String, dynamic>
                                                        data = snapshot.data![0]
                                                            [index];
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
                                            baselineX:
                                                _currentOffsetX.toDouble(),
                                            baselineY:
                                                _currentOffsetY.toDouble(),
                                            lineBarsData: [
                                              LineChartBarData(
                                                dotData: FlDotData(show: false),
                                                spots: snapshot.data![1],
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
                                                interval: 1,
                                                getTitlesWidget: (value, meta) {
                                                  if (value.round() % 100 !=
                                                      0) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  int index =
                                                      (value / 100).round();

                                                  if (index >= 0 &&
                                                      index <
                                                          Constants
                                                              .ranks.length) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 16.0),
                                                      child: Text(Constants
                                                          .ranks[index]),
                                                    );
                                                  }

                                                  if (index == 20) {
                                                    return const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 16.0),
                                                      child: Text("#1"),
                                                    );
                                                  }

                                                  return const SizedBox
                                                      .shrink();
                                                },
                                                showTitles: true,
                                              )),
                                              bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                interval: _displayIntervall,
                                                showTitles: true,
                                                reservedSize: 40,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                      value.toInt().toString());
                                                },
                                              )),
                                              topTitles: const AxisTitles(),
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
                                              horizontalInterval: 1,
                                              getDrawingHorizontalLine:
                                                  (value) {
                                                if (value.round() % 100 != 0) {
                                                  return FlLine(strokeWidth: 0);
                                                }
                                                if ((value / 100).round() *
                                                        100 ==
                                                    1700) {
                                                  return const FlLine(
                                                    color: Colors.red,
                                                    strokeWidth: 2,
                                                    dashArray: [5, 5],
                                                  );
                                                }

                                                return const FlLine(
                                                  color: Colors.grey,
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
                                    SfSlider.vertical(
                                        value: _sliderVerticalStateZoom,
                                        min: -1,
                                        max: 1,
                                        enableTooltip: true,
                                        tooltipTextFormatterCallback:
                                            (actualValue, formattedText) {
                                          return "Current Zoom: ${(100 / _displayIntervall).toInt() / 100}";
                                        },
                                        onChanged: (newValue) {
                                          zoom(newValue);
                                        }),
                                  ],
                                ),
                              ),
                              Slider(
                                value: _sliderHorizontalState,
                                onChanged: (newValue) {
                                  setState(() {
                                    if (_dataLength <= _maxRangeX) {
                                      _currentOffsetX = 0;
                                      _sliderHorizontalState = 0;
                                      return;
                                    }
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
        ],
      ),
    );
  }

  Future<List<dynamic>> makeData() async {
    final data = await RankService().getRankedDataBySeason(
        widget.account["accountId"], _seasonService.getCurrentSeason()!);

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      num yValue = data[i]["total_progress"];
      if (yValue >= 1700) {
        yValue = 1700 + (convertProgressForUnreal(yValue.toDouble()) * 300);
      }
      spots.add(FlSpot(i.toDouble(), yValue.toDouble()));
    }
    if (_currentOffsetY == 0) {
      _currentOffsetY = (data[0]["total_progress"] as int).toDouble() - 10;
      _sliderVerticalStateMovment = _currentOffsetY / 2000;
    }

    _dataLength = data.length;

    return [data, spots];
  }
}
