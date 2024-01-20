import 'package:basic_websocket/utils/api/location.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/ui/location_tree_view.dart';
import 'package:uuid/uuid.dart'; // Import UUID package

class LocationsWidget extends StatefulWidget {
  @override
  _LocationsWidgetState createState() => _LocationsWidgetState();
}

class _LocationsWidgetState extends State<LocationsWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();


  void _addLocation() async {
    // The parentId should be determined by the selected location in the LocationTreeView
    // This will be handled by a callback or state management solution
    String? parentId; // TODO: Set the parentId based on the selected location
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
      // Trigger a refresh in the LocationTreeView if needed
      // This may require a callback or state management solution
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget build implementation remains unchanged
    return Scaffold(
      appBar: AppBar(
        title: const Text("Locations"),
      ),
      body: Column(
        children: [
          Expanded(
            child: LocationTreeView(
              onLocationSelected: (Location location) {
                // Handle location selection
                // You can update the state or perform other actions as needed
                print('Selected location: ${location.name}');
              },
            ),
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
