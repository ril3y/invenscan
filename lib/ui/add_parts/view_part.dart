// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:invenscan/ui/add_parts/edit_screen.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/location.dart';
import 'package:invenscan/utils/api/server_api.dart';

class ViewPartScreen extends StatefulWidget {
  final PartModel part;
  final Location? location;

  const ViewPartScreen({Key? key, required this.part, this.location})
      : super(key: key);

  @override
  _ViewPartScreenState createState() => _ViewPartScreenState();
}

class _ViewPartScreenState extends State<ViewPartScreen> {
  late PartModel part; // Store the part locally in the state
  Location? location;
  bool _isPrinting = false; // To track the printing state

  @override
  void initState() {
    super.initState();
    part = widget.part; // Initialize part from the widget's passed data
    location = widget.location; // Initialize location, it can be null

    // If location is null and part.location.id is not null, fetch the location
    if (location == null && part.location?.id != null) {
      _loadLocation(part.location!.id);
    }
  }

  Future<void> _loadLocation(String locationId) async {
    try {
      Location? fetchedLocation = await ServerApi.getLocationById(locationId);
      if (fetchedLocation != null) {
        if (!mounted) return; // Ensure the widget is still in the tree
        setState(() {
          location = fetchedLocation;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = part.additional_properties['image_url'];

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
            const Divider(),

            // Categories
            if (part.categories != null && (part.categories as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategories(),
                  const Divider(),
                ],
              ),

            // Location Details
            if (location != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationDetails(),
                  const Divider(),
                ],
              ),

            // Additional Properties
            if (part.additional_properties.isNotEmpty)
              _buildAdditionalProperties(),

            const SizedBox(height: 20),

            // Print QR Code Button (disabled while printing)
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : () => _printQrCode(context),
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(_isPrinting ? 'Printing...' : 'Print QR Code'),
            ),

            // Edit Part Button
            ElevatedButton.icon(
              onPressed: () => _navigateToEditPartScreen(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Part'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reloadPart() async {
    if (part.partId != null) {
      // Fetch the updated part data from the server if partId is not null
      PartModel? updatedPart = await ServerApi.getPartById(part.partId!);

      if (part.location?.id != null) {
        _loadLocation(part.location!.id); // Reload location if available
      }

      // Only update the state if the updatedPart is not null
      if (updatedPart != null) {
        setState(() {
          part = updatedPart; // Replace the current part with the updated one
        });
      } else {
        // Handle the case where the part couldn't be fetched (optional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load updated part')),
        );
      }
    } else {
      // Handle the case where partId is null (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Part ID is null')),
      );
    }
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

  void _navigateToEditPartScreen(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditPartScreen(part: part)),
    );

    if (result == true) {
      await _reloadPart(); // Reload part if the user edited it
    }
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
        _buildKeyValueRow("Part Type", part.partType ?? 'N/A'),
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
          children: (part.additional_properties['categories'] as List)
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
        const SizedBox(height: 8),
        _buildKeyValueRow('Location Name', location!.name ?? 'N/A'),
        if (location!.description != null && location!.description!.isNotEmpty)
          _buildKeyValueRow('Description', location!.description!),
      ],
    );
  }

  // Build Additional Properties Section
  Widget _buildAdditionalProperties() {
    // Get only the "additional_properties" key from part.additionalProperties
    Map<String, dynamic> additionalProps = part.additional_properties ?? {};

    if (additionalProps.isEmpty) {
      return SizedBox.shrink(); // Don't display anything if there are no additional properties
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...additionalProps.entries.map((entry) {
          return _buildKeyValueRow(entry.key, entry.value.toString());
        }).toList(),
      ],
    );
  }

  Future<void> _printQrCode(BuildContext context) async {
    setState(() {
      _isPrinting = true; // Disable the button while printing
    });

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code printed successfully')),
        );
      } else {
        throw Exception('Failed to print QR code: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false; // Re-enable the button after printing
        });
      }
    }
  }
}
