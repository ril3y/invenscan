import 'package:flutter/material.dart';
import 'package:invenscan/utils/api/category.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:invenscan/ui/location_tree_view.dart';
import 'package:invenscan/utils/api/location.dart';
import 'package:invenscan/ui/location_selector_screen.dart';

class EditPartScreen extends StatefulWidget {
  final PartModel part;

  const EditPartScreen({super.key, required this.part});

  @override
  _EditPartScreenState createState() => _EditPartScreenState();
}

class _EditPartScreenState extends State<EditPartScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _partNumberController;
  late TextEditingController _partNameController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _supplierController;
  Location? selectedLocation;

  Map<String, TextEditingController> additionalControllers = {};

  // Indicates if the categories are being loaded
  bool _isLoadingCategories = true;

  // Holds all available categories fetched from the server
  List<Category> _allAvailableCategories = [];

  // Holds the categories selected for the part
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    _partNumberController = TextEditingController(text: widget.part.partNumber);
    _partNameController = TextEditingController(text: widget.part.partName);
    _quantityController =
        TextEditingController(text: widget.part.quantity?.toString());
    _descriptionController =
        TextEditingController(text: widget.part.description);
    _supplierController = TextEditingController(text: widget.part.supplier);
    selectedLocation = widget.part.location;

    // Initialize _selectedCategories with existing categories
    if (widget.part.additionalProperties.containsKey('categories')) {
      var categories = widget.part.additionalProperties['categories'];
      if (categories is List) {
        _selectedCategories.addAll(categories.cast<String>());
      } else if (categories is String) {
        // Handle comma-separated string of categories
        _selectedCategories.addAll(categories.split(','));
      }
    }

    // Initialize text editing controllers for additionalProperties
    widget.part.additionalProperties.forEach((key, dynamic value) {
      if (key != 'categories') {
        // Exclude 'categories' from additional properties
        String valueStr = value.toString();
        additionalControllers[key] = TextEditingController(text: valueStr);
        print("$key: $valueStr");
      }
    });
  }

  void _fetchCategories() async {
    try {
      _allAvailableCategories = await ServerApi.fetchCategories();
      setState(() {
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Failed to load categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
      // Handle the error state appropriately
    }
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _partNameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _supplierController.dispose();
    additionalControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updatePartModel() {
    // Read values from text fields
    String updatedPartNumber = _partNumberController.text;
    String updatedPartName = _partNameController.text;
    int? updatedQuantity = int.tryParse(_quantityController.text);
    String updatedDescription = _descriptionController.text;
    String updatedSupplier = _supplierController.text;

    // Create a Map to store additional properties
    Map<String, dynamic> updatedAdditionalProperties = {};

    // Include 'categories' in additionalProperties
    updatedAdditionalProperties['categories'] = _selectedCategories;

    // Add other additional properties
    additionalControllers.forEach((key, controller) {
      updatedAdditionalProperties[key] = controller.text;
    });

    // Create the updated PartModel
    PartModel updatedPart = PartModel(
      partId: widget.part.partId,
      partNumber: updatedPartNumber,
      partName: updatedPartName,
      quantity: updatedQuantity,
      description: updatedDescription,
      supplier: updatedSupplier,
      location: selectedLocation, // Use the selected location
      image_path: widget.part.image_path,
      additionalProperties: updatedAdditionalProperties,
    );

    // Call the ServerApi method to update the part
    ServerApi.updatePart(updatedPart);

    // Update widget.part with the new data
    setState(() {
      widget.part.partNumber = updatedPartNumber;
      widget.part.partName = updatedPartName;
      widget.part.quantity = updatedQuantity;
      widget.part.description = updatedDescription;
      widget.part.supplier = updatedSupplier;
      widget.part.location = selectedLocation;
      widget.part.additionalProperties = updatedAdditionalProperties;
    });

    // Navigate back to the previous screen
              Navigator.pop(context, true);
  }

  void _openLocationSelector() async {
    final Location? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectorScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLocation = result;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Edit Part'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing form fields
            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(labelText: 'Part Number'),
            ),
            TextFormField(
              controller: _partNameController,
              decoration: const InputDecoration(labelText: 'Part Name'),
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(labelText: 'Supplier'),
            ),
            // Additional properties
            ...additionalControllers.entries.map((entry) {
              return TextFormField(
                controller: entry.value,
                decoration: InputDecoration(labelText: entry.key),
              );
            }),
            const SizedBox(height: 20),
            // Categories
            const Text(
              "Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              children: _selectedCategories
                  .map((category) => Chip(
                        label: Text(category),
                        onDeleted: () {
                          setState(() {
                            _selectedCategories.remove(category);
                          });
                        },
                      ))
                  .toList(),
            ),
            _isLoadingCategories
                ? const CircularProgressIndicator()
                : DropdownButton<String>(
                    hint: const Text("Add Category"),
                    onChanged: (String? newValue) {
                      if (newValue != null &&
                          !_selectedCategories.contains(newValue)) {
                        setState(() {
                          _selectedCategories.add(newValue);
                        });
                      }
                    },
                    items: _allAvailableCategories
                        .map<DropdownMenuItem<String>>((Category category) {
                      return DropdownMenuItem<String>(
                        value: category.name,
                        child: Text(category.name),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
            // Location Section
            const Text(
              "Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Display the selected location
            Text(
              selectedLocation != null
                  ? 'Selected Location: ${selectedLocation!.name}'
                  : 'No location selected',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            // Insert the LocationTreeView directly
            SizedBox(
              height: 300, // Adjust the height as needed
              child: LocationTreeView(
                onLocationSelected: (Location location) {
                  setState(() {
                    selectedLocation = location;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Save Changes Button
            ElevatedButton(
              onPressed: _updatePartModel,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    ),
  );
}



}
