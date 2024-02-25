<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:invenscan/utils/api/category.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/server_api.dart';

class EditPartScreen extends StatefulWidget {
  final PartModel part;
=======

import 'package:flutter/material.dart';
import '../../part_data.dart';

class EditPartScreen extends StatefulWidget {
  final PartData part;
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133

  const EditPartScreen({super.key, required this.part});

  @override
  _EditPartScreenState createState() => _EditPartScreenState();
}

class _EditPartScreenState extends State<EditPartScreen> {
<<<<<<< HEAD
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _partNumberController;
  late TextEditingController _partNameController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _supplierController;
  Map<String, TextEditingController> additionalControllers = {};

  // Indicates if the categories are being loaded
  bool _isLoadingCategories = true;

  // Holds all available categories fetched from the server
  List<Category> _allAvailableCategories = [];

  // Holds the categories selected for the part
  final List<String> _selectedCategories = [];
=======
  final _formKey = GlobalKey<FormState>();

  late String supplier; // Example field
  late String partNumber; // Example field
  late int quantity;
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _fetchCategories();

    _partNumberController = TextEditingController(text: widget.part.partNumber);
    _partNameController = TextEditingController(text: widget.part.partName);
    _quantityController =
        TextEditingController(text: widget.part.quantity?.toString());
    _descriptionController =
        TextEditingController(text: widget.part.description);
    _supplierController = TextEditingController(text: widget.part.supplier);

    // Initialize text editing controllers for additionalProperties
    widget.part.additionalProperties.forEach((key, dynamic value) {
      // Ensuring the value is converted to a string.
      // This is a simplistic conversion; consider formatting complex types more appropriately.
      String valueStr = value.toString();
      additionalControllers[key] = TextEditingController(text: valueStr);
      print("$key: $valueStr");
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
    location: widget.part.location,
    image_path: widget.part.image_path,
    additionalProperties: updatedAdditionalProperties,
  );

  // Call the ServerApi method to update the part
  ServerApi.updatePart(updatedPart);

  // Navigate back to the previous screen
  Navigator.pop(context);
}


=======
    supplier = widget.part.supplier; // Initialize fields with part data
    partNumber = widget.part.partNumber;
    quantity = widget.part.quantity;
  }

>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Part'),
      ),
<<<<<<< HEAD
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ...additionalControllers.entries
                  .where((entry) =>
                      entry.key != "categories") // Filter out 'categories'
                  .map((entry) {
                return TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key),
                );
              }),
              const SizedBox(height: 20),
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
              ElevatedButton(
                onPressed: _updatePartModel,
                child: const Text('Save Changes'),
=======
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: supplier,
                decoration: const InputDecoration(labelText: 'Supplier'),
                onSaved: (value) => supplier = value ?? '',
              ),
              TextFormField(
                initialValue: partNumber,
                decoration: const InputDecoration(labelText: 'Part Number'),
                onSaved: (value) => partNumber = value ?? '',
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                initialValue: quantity.toString(), // Convert quantity to string
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity'; 
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
                onSaved: (value) {
                  quantity =
                      int.tryParse(value!) ?? 0; // Convert back to int and save
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Logic to update the part in database
                    Navigator.pop(context); // Return to previous screen
                  }
                },
                child: const Text('Update'),
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
              ),
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
