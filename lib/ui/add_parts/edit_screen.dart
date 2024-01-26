
import 'package:flutter/material.dart';
import '../../part_data.dart';

class EditPartScreen extends StatefulWidget {
  final PartData part;

  const EditPartScreen({super.key, required this.part});

  @override
  _EditPartScreenState createState() => _EditPartScreenState();
}

class _EditPartScreenState extends State<EditPartScreen> {
  final _formKey = GlobalKey<FormState>();

  late String supplier; // Example field
  late String partNumber; // Example field
  late int quantity;

  @override
  void initState() {
    super.initState();
    supplier = widget.part.supplier; // Initialize fields with part data
    partNumber = widget.part.partNumber;
    quantity = widget.part.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Part'),
      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
