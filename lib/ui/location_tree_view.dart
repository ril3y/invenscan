import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/utils/api/location.dart';

class LocationTreeView extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const LocationTreeView({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationTreeViewState createState() => _LocationTreeViewState();
}

class _LocationTreeViewState extends State<LocationTreeView> {
  List<Location> topLevelLocations = [];

  @override
  void initState() {
    super.initState();
    // Initialization logic will be added here later
    _fetchTopLevelLocations();
  }

  void _fetchTopLevelLocations() async {
    try {
      var locations = await ServerApi.fetchLocations();
      setState(() {
        topLevelLocations = locations;
      });
    } catch (e) {
      // Handle errors, e.g., by showing a snackbar or logging
      print('Failed to fetch top-level locations: $e');
    }
  }



  Widget _buildTree() {
    // For now, we are just creating a placeholder UI
    return ListView(
      children: [
        ListTile(
          title: Text('Location 1'),
          onTap: () {}, // Placeholder for tap action
        ),
        ListTile(
          title: Text('Location 2'),
          onTap: () {}, // Placeholder for tap action
        ),
        // More list tiles can be added here as needed
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tree'),
      ),
      body: _buildTree(), // Call the new _buildTree method
    );
  }
}
