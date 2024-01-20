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
        return _buildLocationNode(locations[index]);
      },
    );
  }

  Widget _buildLocationNode(Location location) {
    return ExpansionTile(
      title: Text(location.name),
      children: location.children.map<Widget>(_buildLocationNode).toList(),
      onExpansionChanged: (bool expanded) {
        if (expanded) {
          // Optionally, load children locations dynamically
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tree'),
      ),
      body: topLevelLocations.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildTree(topLevelLocations), // Call the new _buildTree method
    );
  }
}
