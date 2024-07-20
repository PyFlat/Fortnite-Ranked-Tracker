import 'package:flutter/material.dart';

class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  _SearchCardState createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  Future<Map<String, dynamic>> _fetchSelectedItem() async {
    // final response = await http.get(Uri.parse('https://api.example.com/item'));

    // if (response.statusCode == 200) {
    //   return json.decode(response.body);
    // } else {
    //   throw Exception('Failed to load item');
    // }
    return {
      "AccountId": "49a809c144844feea10b90b60b27d8bc",
      "DisplayName": "Anonym 2546",
      "AccountType": "epicgames",
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSelectedItem(),
      builder: (context, snapshot) {
        print(snapshot.data);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return Text('No data available'); //MyCard(item: snapshot.data!);
        } else {
          return Text('No data available');
        }
      },
    );
  }
}
