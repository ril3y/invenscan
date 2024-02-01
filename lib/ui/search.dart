// In search.dart
// ignore_for_file: prefer_const_constructors

import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:flutter/material.dart';
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
  String selectedSearchType = 'name'; // default search type

  @override
  void initState() {
    super.initState();
  }

  Future<void> performSearch(String query, String searchType) async {
    if (query.trim().isEmpty) {
      // If the query is empty, reset the search results and suggestions and do not perform the search
      setState(() {
        searchResults = [];
        suggestions = [];
      });
      return;
    }

    // Continue with the search if the query is not empty
    var searchResult = await ServerApi.performSearch(query, searchType);
    setState(() {
      searchResults = searchResult['searchResults'];
      suggestions = searchResult['suggestions'];
    });
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

  Widget buildLocationTree(Map<String, dynamic> locationNode) {
    if (locationNode.isEmpty) {
      return SizedBox(); // or some placeholder widget
    }

    // Extract current location and parent node
    var currentLocation = locationNode['location'];
    var parent = locationNode['parent'];

    // Create a widget for the current location
    var currentWidget = ListTile(
      title: Text(currentLocation['name']),
      subtitle: Text(currentLocation['description']),
    );

    // Recursively build parent nodes
    var parentWidget = buildLocationTree(parent);

    return Column(
      children: [
        currentWidget,
        parentWidget, // This will be a recursive structure
      ],
    );
  }

  

  AlertDialog buildPartDetailsDialog(
      Map<String, dynamic> partData, BuildContext context) {
    Map<String, dynamic> additionalProperties =
        partData['additional_properties'] ?? {};
    String imageUrl = partData['image_url'] ?? '';
    // String locationId =
    //     partData['location']['id'];

    return AlertDialog(
      title: Text('Part Details'),
      
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 100, width: 100)
                : SizedBox(),
            SizedBox(height: imageUrl.isNotEmpty ? 16 : 0),
            buildDetailText('Part Number:', partData['part_number']),
            buildDetailText('Description:', partData['description']),
            SizedBox(height: 8),
            Text('Additional Properties:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...additionalProperties.entries
                .map((entry) => buildRichText(entry)),
            SizedBox(height: 8),
            Text('Location Path:',
                style: TextStyle(fontWeight: FontWeight.bold)),
                //TODO: Add location tree view 
            // FutureBuilder<List<Location>>(
            //   future: ServerApi.getLocationPath(locationId),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return CircularProgressIndicator();
            //     } else if (snapshot.hasError) {
            //       return Text("Error loading location path");
            //     } else if (snapshot.hasData) {
            //       return Column(
            //         children: snapshot.data!
            //             .map((location) => Text(location!.name))
            //             .toList(),
            //       );
            //     } else {
            //       return Text("No location data available");
            //     }
            //   },
            // ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: Text('Close'))
      ],
    );
  }

  Widget buildDetailText(String title, String? value) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? '', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget buildRichText(MapEntry<String, dynamic> entry) {
    bool isUrl = Uri.tryParse(entry.value)?.hasAbsolutePath ?? false;
    return isUrl
        ? InkWell(
            onTap: () => launch(entry.value),
            child: Text('${entry.key}: ${entry.value}',
                style: TextStyle(color: Colors.blue)))
        : Text('${entry.key}: ${entry.value}');
  }

  Future<void> _showPartDetailsDialog(Map<String, dynamic> partData) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return buildPartDetailsDialog(partData, context);
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
              child: DropdownButton<String>(
                value: selectedSearchType,
                items: <String>['name', 'number']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSearchType = newValue!;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter query',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  performSearch(_searchQuery, selectedSearchType);
                },
              ),
            ),

            // UI for displaying suggestions
            if (suggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(suggestions[index]),
                    onTap: () {
                      // Set the search query to the selected suggestion and perform search
                      setState(() {
                        _searchQuery = suggestions[index];
                      });
                      performSearch(_searchQuery, selectedSearchType);
                    },
                  );
                },
              ),

            // UI for displaying search results
            if (searchResults.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  var result = searchResults[index];
                  String displayText = selectedSearchType == 'name'
                      ? result['name'] ?? ''
                      : result['part_number'] ?? '';

                  return ListTile(
                    title: Text(displayText),
                    subtitle: Text(result['description'] ?? 'No Description'),
                    onTap: () async {
                      // Fetch and show part details
                      await _showPartDetailsDialog(result);
                    },
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          performSearch(_searchQuery, selectedSearchType);
        },
        child: Icon(Icons.search),
      ),
    );
  }
}
