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

  Widget _buildTree(List<Location> locations) {
    return ListView.builder(
      itemCount: locations.length,
      itemBuilder: (BuildContext context, int index) {
        return ExpansionTile(
          title: Text(locations[index].name),
          children: locations[index].children.map<Widget>((child) {
            return _buildTree([child]);
          }).toList(),
          onExpansionChanged: (bool expanded) {
            if (expanded && locations[index].children.isEmpty) {
              // Fetch child locations if the location is expanded and has no children yet
              _fetchChildLocations(locations[index]);
            }
          },
        onTap: () {
            widget.onLocationSelected(locations[index]);
          },
        );
      },
    );
  }

  void _fetchChildLocations(Location parentLocation) async {
    try {
      var children = await ServerApi.getLocationDetails(parentLocation.id);
      setState(() {
        parentLocation.children = children;
      });
    } catch (e) {
      // Handle errors, e.g., by showing a snackbar or logging
      print('Failed to fetch child locations: $e');
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
