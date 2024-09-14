import 'package:flutter/material.dart';
import 'package:invenscan/ui/location_tree_view.dart';
import 'package:invenscan/utils/api/location.dart';

class LocationSelectorScreen extends StatefulWidget {
  @override
  _LocationSelectorScreenState createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  Location? selectedLocation;

  void onLocationSelected(Location location) {
    setState(() {
      selectedLocation = location;
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: LocationTreeView(
              onLocationSelected: onLocationSelected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: selectedLocation != null ? _confirmSelection : null,
              child: const Text('Confirm Selection'),
            ),
          ),
        ],
      ),
    );
  }
}
