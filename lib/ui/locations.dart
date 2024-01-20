import 'package:basic_websocket/utils/api/location.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:uuid/uuid.dart'; // Import UUID package

class LocationsWidget extends StatefulWidget {
  @override
  _LocationsWidgetState createState() => _LocationsWidgetState();
}

class _LocationsWidgetState extends State<LocationsWidget> {
  List<Location> topLevelLocations = [];
  List<Location> childLocations = [];
  Location? selectedTopLevelLocation;
  Location? selectedChildLocation;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTopLevelLocations();
  }

  void fetchTopLevelLocations() async {
              var locations = await ServerApi.fetchLocations();
    setState(() {
      topLevelLocations = locations;
      // Ensure the selected location is still valid, otherwise set it to null
      if (!topLevelLocations.contains(selectedTopLevelLocation)) {
        selectedTopLevelLocation = null;
      }
    });

    setState(() {
    });
  }

  void fetchChildLocations(String parentLocationId) async {
    try {
      var locationDetails = await ServerApi.getLocationDetails(parentLocationId);
      setState(() {
        childLocations = locationDetails;
        // Reset selected child location if the new list does not contain the old value
        if (!childLocations.contains(selectedChildLocation)) {
          selectedChildLocation = null;
        }
      });
    } catch (e) {
      // Handle errors, e.g., by showing a snackbar or logging
      print('Failed to fetch location details: $e');
    }
  }

  void _addLocation() async {
    String? parentId = selectedTopLevelLocation?.id ;
    String name = _nameController.text;
    String description = _descriptionController.text;

    if (name.isEmpty || description.isEmpty) {
      // Show error if name or description is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and description cannot be empty')),
      );
      return;
    }

    var newLocation = {
      "name": name,
      "description": description,
      "parent_id": parentId
    };

    try {
      await ServerApi.addLocation(newLocation);
      // Clear the text fields after successful submission
      _nameController.clear();
      _descriptionController.clear();
      // Optionally, refresh the locations list
      fetchTopLevelLocations();
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Locations"),
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding
            ),
          ),
          ElevatedButton(
            onPressed: _addLocation,
            child: const Text('Add Location'),
          ),
          // Add button for adding a new location
        ],
      ),
    );
  }
}
