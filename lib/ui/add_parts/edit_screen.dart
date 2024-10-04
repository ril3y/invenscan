import 'package:flutter/material.dart';
import 'package:invenscan/utils/api/category.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:invenscan/ui/location_tree_view.dart';
import 'package:invenscan/utils/api/location.dart';

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

  bool _isLoadingCategories = true;
  List<Category> _allAvailableCategories = [];
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    // Initialize controllers for core properties
    _partNumberController = TextEditingController(text: widget.part.partNumber);
    _partNameController = TextEditingController(text: widget.part.partName);
    _quantityController =
        TextEditingController(text: widget.part.quantity?.toString());
    _descriptionController =
        TextEditingController(text: widget.part.description);
    _supplierController = TextEditingController(text: widget.part.supplier);
    selectedLocation = widget.part.location;

    // Initialize _selectedCategories with existing categories
    if (widget.part.categories != null) {
      _selectedCategories
          .addAll(widget.part.categories!.map((category) => category.name));
    }

    // Initialize text controllers only for the "additional_properties"
    Map<String, dynamic> additionalProperties =
        widget.part.additional_properties;

    additionalProperties.forEach((key, dynamic value) {
      additionalControllers[key] =
          TextEditingController(text: value.toString());
    });

    // // Initialize text controllers for the "additional_properties"
    // Map<String, dynamic> additionalProperties =
    //     widget.part.additionalProperties ??
    //         {}; // No need for 'additional_properties' inside the field

    // Create a TextEditingController for each key in additionalProperties
    // additionalProperties.forEach((key, dynamic value) {
    //   additionalControllers[key] =
    //       TextEditingController(text: value.toString());
    // });
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
    // Gather the updated values from text fields
    String updatedPartNumber = _partNumberController.text;
    String updatedPartName = _partNameController.text;
    int? updatedQuantity = int.tryParse(_quantityController.text);
    String updatedDescription = _descriptionController.text;
    String updatedSupplier = _supplierController.text;

    // Create a Map for the updated "additional_properties"
    Map<String, dynamic> updatedAdditionalProperties =
        widget.part.additional_properties = {};

    // Update each additional property with the edited value
    additionalControllers.forEach((key, controller) {
      updatedAdditionalProperties[key] =
          controller.text; // Update the values based on user input
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
      additional_properties: updatedAdditionalProperties, // Set directly
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
      widget.part.additional_properties =
          updatedAdditionalProperties; // Update the map
    });

    // Navigate back to the previous screen
    Navigator.pop(context, true);
  }

  List<Widget> buildAdditionalPropertyFields(
      Map<String, TextEditingController> additionalControllers) {
    return additionalControllers.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: entry.value,
          decoration: InputDecoration(
            labelText:
                _formatKey(entry.key), // Format key to a human-readable label
          ),
        ),
      );
    }).toList();
  }

// Function to format the keys
  String _formatKey(String key) {
    // Converts keys like 'part_number' to 'Part Number'
    return key.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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
              // Form fields for core properties
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
              const SizedBox(height: 20),

              // Additional properties fields
              const Text(
                "Additional Properties",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...buildAdditionalPropertyFields(additionalControllers),

              // Categories
              const Text(
                'Categories',
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

              // Location section (now only at the bottom)
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                selectedLocation != null
                    ? 'Selected Location: ${selectedLocation!.name}'
                    : 'No location selected',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
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
