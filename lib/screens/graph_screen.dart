import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/individual_page_header.dart';

import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../components/graph_bottom_sheet.dart';
import 'dart:math' as math;

import '../core/talker_service.dart';

class GraphScreen extends StatefulWidget {
  final Map<String, dynamic>? account;

  const GraphScreen({super.key, this.account});
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

  double _sliderVerticalStateMovment = 0;

  double _sliderVerticalStateZoom = 0.5;
  double _sliderHorizontalState = 0;

  int _dataLength = 0;

  late Future<List<dynamic>> _dataFuture;

  final GlobalKey _key = GlobalKey();

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      items.add({
        "visible": true,
        "displayName": widget.account!["displayName"],
        "accountId": widget.account!["accountId"]
      });
    }

    _resetMovement();
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
      _dataFuture = makeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (items.length == 1 &&
        items.first["season"] == null &&
        widget.account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheetWithItems(context, openSeasonSelection: true);
      });
    }
  }

  void _refreshData() {
    setState(() {
      _dataFuture = makeData();
    });
  }

  void zoom(double newValue) {
    setState(() {
      _sliderVerticalStateZoom = newValue;
      double v = 0;
      if (newValue < 0) {
        v = math.pow(2, newValue).toDouble();
      } else {
        v = math.pow(10, newValue).toDouble();
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

  void showModalBottomSheetWithItems(BuildContext context,
      {bool openSeasonSelection = false}) async {
    List<Map<String, dynamic>>? result =
        await showModalBottomSheet<List<Map<String, dynamic>>?>(
      context: context,
      builder: (BuildContext context) {
        return GraphBottomSheetContent(
          items: [...items],
          openSeasonSelection: openSeasonSelection,
        );
      },
    );

    if (result != null) {
      items = [...result];
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(items.isNotEmpty
            ? "Graph of ${items.map((element) => element["displayName"]).toSet().join(", ")}"
            : "GraphScreen"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheetWithItems(context);
        },
        label: const Text("Edit"),
        icon: const Icon(Icons.edit_rounded),
      ),
      body: Column(
        children: [
          IndividualPageHeader(
            onSeasonSelected: _refreshData,
            resetSliders: _resetMovement,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: !items.any(
                    (item) => item['season'] != null && item['visible'] == true)
                ? const Center(
                    child: Text("Please select a season + user",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600)))
                : FutureBuilder(
                    future: _dataFuture,
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        talker.error(snapshot.error);
                        return Container();
                      } else if (snapshot.hasData) {
                        return _buildGraph(snapshot.data!);
                      } else {
                        return Container();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(List<dynamic> data) {
    return AspectRatio(
      aspectRatio: 1.75,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildVerticalSlider(),
                _buildChart(data),
                _buildZoomSlider(),
              ],
            ),
          ),
          _buildHorizontalSlider(),
        ],
      ),
    );
  }

  Widget _buildVerticalSlider() {
    return SfSlider.vertical(
      value: _sliderVerticalStateMovment,
      onChanged: (newValue) {
        setState(() {
          _sliderVerticalStateMovment = newValue;
          _currentOffsetY = 2000 * _sliderVerticalStateMovment;
        });
      },
      min: 0,
      max: 1,
    );
  }

  Widget _buildZoomSlider() {
    return SfSlider.vertical(
      value: _sliderVerticalStateZoom,
      min: -1,
      max: 1,
      enableTooltip: true,
      tooltipTextFormatterCallback: (actualValue, formattedText) {
        return "Current Zoom: ${(100 / _displayIntervall).toInt() / 100}";
      },
      onChanged: (newValue) {
        zoom(newValue);
      },
    );
  }

  Widget _buildHorizontalSlider() {
    return Slider(
      value: _sliderHorizontalState,
      onChanged: (newValue) {
        setState(() {
          if (_dataLength <= _maxRangeX) {
            _currentOffsetX = 0;
            _sliderHorizontalState = 0;
            return;
          }
          _sliderHorizontalState = newValue;
          _currentOffsetX = (_dataLength - _maxRangeX) * newValue;
        });
      },
      min: 0,
      max: 1,
    );
  }

  Widget _buildChart(List<dynamic> data) {
    return Expanded(
      child: Listener(
        onPointerDown: _onClick,
        onPointerMove: _updatePosition,
        onPointerUp: _onRelease,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            double delta = event.scrollDelta.dy / 2000;
            if (_sliderVerticalStateZoom + delta > 1) {
              delta = 0;
            } else if (_sliderVerticalStateZoom + delta < -1) {
              delta = 0;
            }
            zoom(_sliderVerticalStateZoom + delta);
          }
        },
        child: LineChart(
          key: _key,
          LineChartData(
            lineTouchData: LineTouchData(
              touchSpotThreshold: 20,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                maxContentWidth: 200,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final int index = touchedSpot.spotIndex;
                    final int test = touchedSpot.barIndex;

                    if (data.isNotEmpty &&
                        index >= 0 &&
                        index < ((data[test]["data"] as List).length)) {
                      final itemData = data[test]["data"][index];

                      return LineTooltipItem(
                        'Match: ${itemData["totalMatchId"]}\n'
                        'Rank: ${itemData["rank"]} ${itemData["progress"]}\n'
                        'Datetime: ${itemData["datetime"]}\n'
                        'Daily Match: ${itemData["dailyMatchId"]}',
                        const TextStyle(color: Colors.black, fontSize: 14),
                      );
                    } else {
                      return const LineTooltipItem("", TextStyle());
                    }
                  }).toList();
                },
              ),
            ),
            baselineX: _currentOffsetX.toDouble(),
            baselineY: _currentOffsetY.toDouble(),
            lineBarsData: [
              for (Map chart in data)
                LineChartBarData(
                    dotData: const FlDotData(show: false),
                    spots: chart["spots"],
                    color: chart["color"]),
            ],
            titlesData: _buildTitlesData(),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            gridData: _buildGridData(),
            minX: _currentOffsetX,
            maxX: _currentOffsetX + _maxRangeX,
            minY: _currentOffsetY,
            maxY: _currentOffsetY + _maxRangeY,
            clipData: const FlClipData.all(),
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: const AxisTitles(axisNameWidget: SizedBox(width: 40)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          reservedSize: 125,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.round() % 100 != 0) {
              return const SizedBox.shrink();
            }
            int index = (value / 100).round();
            if (index >= 0 && index < Constants.ranks.length) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(Constants.ranks[index]),
              );
            }
            if (index == 20) {
              return const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text("#1"),
              );
            }
            return const SizedBox.shrink();
          },
          showTitles: true,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          interval: _displayIntervall,
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(value.toInt().toString());
          },
        ),
      ),
      topTitles: const AxisTitles(),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) {
        if (value.round() % 100 != 0) {
          return const FlLine(strokeWidth: 0);
        }
        if ((value / 100).round() * 100 == 1700) {
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
    );
  }

  Future<List<dynamic>> makeData() async {
    List<Map<String, dynamic>> result = [];
    for (Map item in items) {
      if (item["season"] == null || item["visible"] == false) {
        continue;
      }
      final List data = (await RankService().getSeasonBySeasonId(
          item["accountId"], item["season"]["id"],
          isAscending: true))["data"];

      List<FlSpot> spots = [];
      for (int i = 0; i < data.length; i++) {
        num yValue = data[i]["totalProgress"];
        if (yValue >= 1700) {
          yValue = 1700 + (convertProgressForUnreal(yValue.toDouble()) * 300);
        }
        spots.add(FlSpot(i.toDouble(), yValue.toDouble()));
      }
      if (_currentOffsetY == 0) {
        num start = data[0]["totalProgress"] as num;
        if (start >= 1700) {
          start = 1700 + (convertProgressForUnreal(start.toDouble()) * 300);
        }
        _currentOffsetY = start - 10;
        _sliderVerticalStateMovment = _currentOffsetY / 2000;
      }
      if (data.length > _dataLength) {
        _dataLength = data.length;
      }
      result.add({"data": data, "spots": spots, "color": item["color"]});
    }

    return result.reversed.toList();
  }
}
