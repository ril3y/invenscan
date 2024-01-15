// In search.dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> suggestions = [];
  String serverUrl = '';
  List<Map<String, dynamic>> searchResults = [];
  String _searchQuery = ''; // Store the current search query

  @override
  void initState() {
    super.initState();
    _loadServerDetails();
  }

  Future<Map<String, dynamic>?> fetchFullPartData(String partNumber) async {
    var url = Uri.parse('$serverUrl/get_part/$partNumber');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Handle the error
      print('Failed to fetch full part data');
      return null;
    }
  }

  Future<void> performSearch(String query) async {
    var url = Uri.parse('$serverUrl/search/$query');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        Future<void> performSearch(String query) async {
          var url = Uri.parse('$serverUrl/search/$query');
          var response = await http.get(url);

          if (response.statusCode == 200) {
            var data = json.decode(response.body);
            setState(() {
              searchResults = data['search_results'];
              suggestions = data['suggestions'];
            });
          } else {
            // Handle the error
            print('Failed to load search results');
          }
        }

        searchResults = (data['search_results'] as List<dynamic>)
            .map((result) => result as Map<String, dynamic>)
            .toList();

        suggestions = data['suggestions'];
      });
    } else {
      // Handle the error
      print('Failed to load search results');
    }
  }

  Future<void> _loadServerDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

    if (serverAddress != null && serverPort != null) {
      setState(() {
        serverUrl = 'http://$serverAddress:$serverPort';
      });
    }
  }

  Future<void> _showPartDataDialog(Map<String, dynamic> partData) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Part Data'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Part Number: ${partData['part_number']}'),
              Text('Description: ${partData['description']}'),
              // Add more part data fields here as needed
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> buildAdditionalProperties(Map<String, dynamic> properties) {
    List<Widget> propertyWidgets = [];

    // Iterate through the map
    properties.forEach((key, value) {
      // Create a widget for each property
      var propertyWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bold label
          Text(
            key,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          // Italic value
          Text(
            value.toString(),
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8.0), // Add some spacing between properties
        ],
      );

      propertyWidgets.add(propertyWidget);
    });

    return propertyWidgets;
  }

  Future<void> _showPartDetailsDialog(Map<String, dynamic> partData) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // Extract additional properties if available
        Map<String, dynamic> additionalProperties =
            partData.containsKey('additional_properties')
                ? partData['additional_properties']
                : {};

        return AlertDialog(
          title: Text('Part Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (partData.containsKey('image_url') &&
                    partData['image_url'].isNotEmpty)
                  Image.network(
                    partData['image_url'],
                    height: 100, // Adjust the height as needed
                    width: 100, // Adjust the width as needed
                  ),
                SizedBox(height: 16), // Add some spacing
                Text(
                  'Part Number:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  partData['part_number'],
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8), // Add some spacing
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  partData['description'],
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8), // Add spacing before additional properties
                Text(
  'Additional Properties:',
  style: TextStyle(fontWeight: FontWeight.bold),
),
...additionalProperties.entries.map((entry) {
  // Check if the value is a URL
  bool isUrl = Uri.tryParse(entry.value)?.hasAbsolutePath ?? false;

  return isUrl
      ? InkWell(
          onTap: () {
            // Launch the URL
            launch(entry.value);
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${entry.key}: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                TextSpan(
                  text: entry.value,
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                ),
              ],
            ),
          ),
        )
      : RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${entry.key}: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              TextSpan(
                text: entry.value,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black),
              ),
            ],
          ),
        );
}).toList(),

              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search Parts'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Search for a part',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter part number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value; // Update the search query
                  });
                  performSearch(value); // Trigger search as you type
                },
              ),
            ),
            // Display suggestions as you type
            ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () async {
                    setState(() {
                      _searchQuery =
                          suggestion; // Set the search query to the suggestion
                    });
                    // Fetch the full part data from the server
                    final fullPartData = await fetchFullPartData(suggestion);
                    if (fullPartData != null) {
                      // Show the part details dialog with the full part data
                      _showPartDetailsDialog(fullPartData);
                    }
                  },
                );
              },
            ),
            // Display search results
            ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(searchResults[index]['part_number']),
                  subtitle: Text(searchResults[index]['description']),
                  // Add more details as needed
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Submit the search with the current query
          performSearch(_searchQuery);
        },
        child: Icon(Icons.search),
      ),
    );
  }
}
