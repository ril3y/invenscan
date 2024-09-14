// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:invenscan/ui/add_parts/edit_screen.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/location.dart';
import 'package:invenscan/utils/api/server_api.dart';

class ViewPartScreen extends StatelessWidget {
  final PartModel part;
  final Location? location;

  const ViewPartScreen({Key? key, required this.part, this.location})
      : super(key: key);

  Future<void> _printQrCode(BuildContext context) async {
    try {
      // Fetch part name and part number from the part object
      String? partNumber = part.partNumber;
      String? partName = part.partName;

      // Ensure that at least one of partName or partNumber is available
      if ((partNumber == null || partNumber.isEmpty) &&
          (partName == null || partName.isEmpty)) {
        throw Exception(
            "Part number or name must be available to generate QR.");
      }

      // Call the API service and pass part name and part number
      var response = await ServerApi.printQrCode(
          partName: partName, partNumber: partNumber);

      // Check if the response is successful
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code printed successfully')),
        );
      } else {
        throw Exception('Failed to print QR code: ${response.body}');
      }
    } catch (e) {
      // Handle any errors and show them in a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = part.additionalProperties['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Part'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                ),
              ),
            const SizedBox(height: 16),

            // Part Name
            Text(
              part.partName ?? 'No Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Main Details
            _buildMainDetails(),
            Divider(),

            // Categories
            if (part.additionalProperties['categories'] != null &&
                (part.additionalProperties['categories'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategories(),
                  Divider(),
                ],
              ),

            // Location Details
            if (location != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationDetails(),
                  Divider(),
                ],
              ),

            // Additional Properties
            if (part.additionalProperties.isNotEmpty)
              _buildAdditionalProperties(),

            // Add the QR code print button at the bottom
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _printQrCode(context),
              icon: Icon(Icons.qr_code),
              label: Text('Print QR Code'),
            ),
            ElevatedButton.icon(
              onPressed: () => _navigateToEditPartScreen(context, part),
              icon: Icon(Icons.edit),
              label: Text('Edit Part'),
              
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format keys to human-readable labels
  String _formatKey(String key) {
    String result = key.replaceAll('_', ' ');
    result = result.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (Match m) => '${m[1]} ${m[2]}');
    result = result
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
    return result;
  }

  void _navigateToEditPartScreen(BuildContext context, PartModel part) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditPartScreen(part: part)),
    );

    if (result == true) {
    // If the result is true, meaning the part was edited, reload the part
    await _reloadPart();
  }
  }

  Future<void> _reloadPart() async {
  // Example function to re-fetch the updated part data
  part = await ServerApi.getPartById(part.partId);
  setState(() {
    // Trigger a UI rebuild with the new part data
  });
}

  // Helper method to build key-value rows
  Widget _buildKeyValueRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _formatKey(key),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Build Main Details Section
  Widget _buildMainDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKeyValueRow('Part Number', part.partNumber ?? 'N/A'),
        _buildKeyValueRow('Quantity', part.quantity?.toString() ?? 'N/A'),
        _buildKeyValueRow('Supplier', part.supplier ?? 'N/A'),
        if (part.description != null && part.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            part.description!,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ],
    );
  }

  // Build Categories Section
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: (part.additionalProperties['categories'] as List)
              .map<Widget>((category) => Chip(
                    label: Text(category),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Build Location Details Section
  Widget _buildLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildKeyValueRow('Location ID', location!.id.toString()),
        _buildKeyValueRow('Location Name', location!.name ?? 'N/A'),
        if (location!.description != null && location!.description!.isNotEmpty)
          _buildKeyValueRow('Description', location!.description!),
        if (location!.parentId != null)
          _buildKeyValueRow('Parent ID', location!.parentId.toString()),
      ],
    );
  }

  // Build Additional Properties Section
  Widget _buildAdditionalProperties() {
    // Exclude keys that are already displayed
    final excludedKeys = {
      'image_url',
      'categories',
      'part_number',
      'part_name',
      'quantity',
      'description',
      'supplier',
      'part_id',
      'location',
      'image_path',
    };

    final propertiesToDisplay = part.additionalProperties.entries
        .where((entry) =>
            !excludedKeys.contains(entry.key) &&
            entry.value != null &&
            entry.value.toString().isNotEmpty)
        .toList();

    if (propertiesToDisplay.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...propertiesToDisplay.map((entry) {
          return _buildKeyValueRow(entry.key, entry.value.toString());
        }).toList(),
      ],
    );
  }
}
