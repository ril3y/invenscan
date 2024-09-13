import 'package:flutter/material.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/location.dart'; // Assuming location is imported like this

class ViewPartScreen extends StatelessWidget {
  final PartModel part;
  final Location? location; // Assuming the part model includes a location object

  const ViewPartScreen({Key? key, required this.part, this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the image_url from additionalProperties as the image source
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
            // Top Row with Image on the Left and Part Info on the Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Part Image if available
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 100, // Set a fixed width for the image
                      height: 100, // Set a fixed height for the image
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partName ?? 'No Name',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Part Number: ${part.partNumber ?? 'N/A'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Display Categories as Chips if available
            if (part.additionalProperties['categories'] != null &&
                (part.additionalProperties['categories'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Categories:",
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
              ),

            const SizedBox(height: 16),

            // Display part model key-value pairs (excluding image_url and displayed ones)
            _buildTextRow('Quantity:', part.quantity?.toString()),
            _buildTextRow('Supplier:', part.supplier),
            _buildTextRow('Description:', part.description),

            const SizedBox(height: 16),

            // Display Location Details if available
            if (location != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildTextRow('Location ID:', location!.id),
                  _buildTextRow('Location Name:', location!.name),
                  _buildTextRow('Location Description:', location!.description),
                  if (location!.parentId != null)
                    _buildTextRow('Parent ID:', location!.parentId),
                ],
              ),

            const SizedBox(height: 16),

            // Display Additional Properties (excluding displayed keys like image_url, categories, etc.)
            if (part.additionalProperties.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Properties:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Loop through additionalProperties to display them
                  ...part.additionalProperties.entries
                      .where((entry) =>
                          entry.key != 'image_url' && // Exclude 'image_url'
                          entry.key != 'categories' && // Exclude categories
                          entry.value != null &&
                          entry.value.toString().isNotEmpty)
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildKeyValueRow(entry.key, entry.value.toString()),
                        );
                      }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build text rows with the key on one line and value optionally on the next line with ellipsis if long
  Widget _buildKeyValueRow(String key, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key, // Key should never wrap
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis, // Ensures the key stays on one line
        ),
        Text(
          value, // Value can wrap if needed, but will trail off if too long
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // Prevents value wrapping too much
        ),
      ],
    );
  }

  // Helper method to build the non-wrapping key-value pairs for part data
  Widget _buildTextRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox(); // Return an empty widget if value is null or empty
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
            maxLines: 1, // Prevent wrapping of value
            overflow: TextOverflow.ellipsis, // Add ellipsis for long values
          ),
        ],
      ),
    );
  }
}
