import 'package:basic_websocket/utils/api/location.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';

class LocationsWidget extends StatefulWidget {
  @override
  _LocationsWidgetState createState() => _LocationsWidgetState();
}

class _LocationsWidgetState extends State<LocationsWidget> {
  List<Location> topLevelLocations = [];
  List<Location> childLocations = [];
  Location? selectedTopLevelLocation;
  Location? selectedChildLocation;

  @override
  void initState() {
    super.initState();
    fetchTopLevelLocations();
  }

  void fetchTopLevelLocations() async {
    var _locations = ServerApi.fetchLocations();
  }

  void fetchChildLocations(Location parentLocation) async {
    // Fetch child locations based on parentLocation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Locations"),
      ),
      body: Column(
        children: [
          DropdownButton<Location>(
            value: selectedTopLevelLocation,
            onChanged: (Location? newValue) {
              setState(() {
                selectedTopLevelLocation = newValue;
                fetchChildLocations(newValue!);
              });
            },
            items: topLevelLocations.map<DropdownMenuItem<Location>>((Location location) {
              return DropdownMenuItem<Location>(
                value: location,
                child: Text(location.name),
              );
            }).toList(),
          ),
          if (selectedTopLevelLocation != null)
            DropdownButton<Location>(
              value: selectedChildLocation,
              onChanged: (Location? newValue) {
                setState(() {
                  selectedChildLocation = newValue;
                });
              },
              items: childLocations.map<DropdownMenuItem<Location>>((Location location) {
                return DropdownMenuItem<Location>(
                  value: location,
                  child: Text(location.name),
                );
              }).toList(),
            ),
          // Add button for adding a new location
        ],
      ),
    );
  }
}
