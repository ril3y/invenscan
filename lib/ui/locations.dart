// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors

import 'package:basic_websocket/ui/location_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/location.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _parentIdController = TextEditingController();
  // final GlobalKey<LocationTreeViewState> locationTreeViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void onLocationSelected(Location location) {
    setState(() {
      selectedTopLevelLocation = location;
      if (location.name == "Locations") {
        //This is the default location and the new location
        //Will be a top level location
        _parentIdController.text = "";
        selectedChildLocation = null;
      } else {
        _parentIdController.text = location.name;
      }
      // Optionally reset or update other related state variables
      // For example, you might want to reset selectedChildLocation
    });
  }

  void _addLocation() async {
    String? parentId;
    if (selectedTopLevelLocation?.id == "root") {
      parentId = null;
    } else {
      parentId = selectedTopLevelLocation?.id;
    }
    String name = _nameController.text;
    String description = _descriptionController.text;

    if (name.isEmpty || description.isEmpty) {
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
      _parentIdController.clear();
      _nameController.clear();
      _descriptionController.clear();
      // refreshLocationTree();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add location: $e')),
      );
    }
  }

  // void refreshLocationTree() async {
  //   locationTreeViewKey.currentState?.refreshTree();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Locations"),
      ),
      body: Column(
        children: [
          Expanded(
            child: LocationTreeView(
              // key: locationTreeViewKey,
              // refreshTree: refreshLocationTree,
              onLocationSelected: onLocationSelected, // Pass the callback here
            ),
          ),
          TextField(
            controller: _parentIdController,
            decoration: const InputDecoration(
              labelText: 'Parent Location',
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          ElevatedButton(
            onPressed: _addLocation,
            child: const Text('Add Location'),
          ),
        ],
      ),
    );
  }
}
