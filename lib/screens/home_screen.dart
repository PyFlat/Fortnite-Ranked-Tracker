import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context);
    _apiService
        .periodicGetRequests(); // Example method call for periodic requests
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _apiService.bulkProgress,
          child: Text('Fetch Data'),
        ),
      ),
    );
  }
}
