import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> data = await ApiService.bulkProgress(context);
      setState(() {
        _data = data;
      });
    } catch (e) {
      // Handle error
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text('No Data'))
              : ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    return Card(
                      margin: EdgeInsets.all(10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Game ID: ${item['gameId']}'),
                            Text('Track GUID: ${item['trackguid']}'),
                            Text('Account ID: ${item['accountId']}'),
                            Text('Ranking Type: ${item['rankingType']}'),
                            Text('Last Updated: ${item['lastUpdated']}'),
                            Text(
                                'Current Division: ${item['currentDivision']}'),
                            Text(
                                'Highest Division: ${item['highestDivision']}'),
                            Text(
                                'Promotion Progress: ${item['promotionProgress']}'),
                            Text(
                                'Current Player Ranking: ${item['currentPlayerRanking'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
