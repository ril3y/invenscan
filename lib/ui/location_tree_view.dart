// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_super_parameters, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/location.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

class LocationNode {
  final Location location;
  List<LocationNode> children;

  LocationNode({required this.location, List<LocationNode>? children})
      : children = children ?? [];
  void addChild(LocationNode child) {
    children.add(child);
  }
}

class LocationTreeView extends StatefulWidget {
  final Function(Location) onLocationSelected;
  // final Function() refreshTree;

  // const LocationTreeView(
  //     {Key? key, required this.onLocationSelected, required this.refreshTree})
  //     : super(key: key);

  const LocationTreeView({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  _LocationTreeViewState createState() => _LocationTreeViewState();
}

class _LocationTreeViewState extends State<LocationTreeView> {
  late final TreeController<LocationNode> treeController;
  var loc = Location(id: 'root', name: 'Locations', description: 'Locations');
  late final LocationNode root = LocationNode(location: loc);

  Location? selectedLocation; // Variable to store the selected location ID
  Set<String> expandedNodeIds = {}; // Set to track expanded nodes
  late List<Location> locations;
  List<LocationNode> roots = [];
  bool isLoadingTree = true; // Add a new variable to track tree loading status

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    refreshTree();
  }

  void refreshTree() {
    treeController = TreeController<LocationNode>(
      roots: [root],
      childrenProvider: (LocationNode node) => node.children,
    );
    buildLocationTree(root).then((_) {
      setState(() {
        isLoadingTree = false; // Update the state when tree is built
      });
    });
  }

  void confirmDeleteLocation(String locationId) async {
    try {
      var response = await ServerApi.previewDeleteLocation(locationId);

      // Safely extract affected parts count
      var affectedParts = 0;
      if (response['affected_parts_count'] != null) {
        affectedParts = response['affected_parts_count'] as int;
      }

      // Safely extract affected children count
      var affectedChildren = 0;
      if (response['affected_children_count'] != null) {
        affectedChildren = response['affected_children_count'] as int;
      }

      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text(
                'Deleting this location will affect $affectedParts parts and $affectedChildren child locations. Do you want to proceed?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        var response = await ServerApi.deleteLocation(locationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success: Deleted $locationId')),
        );
        if (kDebugMode) {
          print("successfully deleted $locationId $response.body");
        }
      }
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> buildLocationTree(LocationNode root) async {
    root.children.clear();
    Map<String, LocationNode> nodes = {};

    locations = await ServerApi.fetchLocations();

    if (kDebugMode) {
      print("buildLocationTree called");
    }
    // Initialize nodes for each location
    for (var loc in locations) {
      nodes[loc.id] = LocationNode(location: loc);
    }

    // Assign children to their respective parent nodes
    for (var loc in locations) {
      if (loc.parentId == null) {
        LocationNode _locationNode = LocationNode(location: loc);
        root.children.add(_locationNode); // Top-level nodes
      } else if (nodes.containsKey(loc.parentId)) {
        for (var ln in root.children) {
          if (ln.location.id == loc.parentId) {
            ln.children.add(nodes[loc.id]!);
          }
        }
        nodes[loc.parentId]!.children.add(nodes[loc.id]!); // Children nodes
      }
    }
  }

  void _deleteLocation(String locationId) async {
    try {
      await ServerApi.deleteLocation(locationId);
      // Optionally, show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location deleted successfully')),
      );
      refreshTree(); // Refresh the tree to reflect the changes
    } catch (e) {
      // Handle errors, for example, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete location: $e')),
      );
    }
  }

  void onLocationSelected(Location location) {
    if (kDebugMode) {
      print("Location selected: ${location.id}");
    }
    widget.onLocationSelected(
        location); // Pass the selected location back to the parent widget
  }




  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
  }
