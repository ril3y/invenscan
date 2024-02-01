import 'dart:io';

import 'package:basic_websocket/scanner_service.dart';
import 'package:basic_websocket/utils/api/server_api_exception.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/utils/api/location.dart';
import 'package:basic_websocket/utils/camera_capture.dart';
import 'package:flutter/services.dart';
import 'package:basic_websocket/utils/api/partmodel.dart';
import 'package:basic_websocket/ui/location_tree_view.dart';

class AddPartForm extends StatefulWidget {
  const AddPartForm({super.key});

  @override
  _AddPartFormState createState() => _AddPartFormState();
}

class _AddPartFormState extends State<AddPartForm> {
  // Add TextEditingControllers for form fields
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _partNumberController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScannerService _scannerService = ScannerService();

  Location? _selectedLocation;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
  }

  // Handle location selection from LocationTreeView
  void _onLocationSelected(Location selectedLocation) {
    setState(() {
      _selectedLocation = selectedLocation;
    });
  }

  void _refreshLocationTree() {
    // Implement if needed. For example, you could call setState here
  }

  Future<void> _navigateAndCaptureImage() async {
    final capturedImage = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );
    if (capturedImage != null) {
      setState(() {
        _imagePath = capturedImage.path;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _partNameController.dispose();
    _partNumberController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartNumberField() {
    return TextField(
      controller: _partNumberController,
      decoration: InputDecoration(
        labelText: 'Part Number',
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _scanPartNumber,
        ),
      ),
    );
  }

  Future<void> _scanPartNumber() async {
    try {
      var scannedData = await _scannerService.scanBarcode();
      // Assuming the scanned data is directly the part number
      _partNumberController.text = String.fromCharCodes(scannedData);
    } catch (e) {
      // Handle any errors here
      print('Error scanning: $e');
    }
  }

  Widget _buildImagePreview() {
    return _imagePath == null
        ? Container()
        : Stack(
            alignment: Alignment.topRight,
            children: [
              Image.file(File(_imagePath!), fit: BoxFit.cover),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
            ],
          );
  }

   


  Future<void> _submitForm() async {
    try {
      PartModel partData = PartModel(
        partNumber: _partNumberController.text.isNotEmpty
            ? _partNumberController.text
            : null,
        partName: _partNameController.text.isNotEmpty
            ? _partNameController.text
            : null,
        quantity: int.tryParse(_quantityController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        supplier: _supplierController.text.isNotEmpty
            ? _supplierController.text
            : null,
        location:
            _selectedLocation, // Assuming _selectedLocation has a toJson method
      );

      var response = await ServerApi.addPart(partData.toJson());
      Navigator.of(context).pop(response);
    } on ServerApiException catch (apiException) {
      // Handle specific API errors
      //_showErrorDialog('Failed to submit part', apiException.message);
      print('API error submitting part: ${apiException.message}');
    } on Exception catch (genericException) {
      // Handle any other exceptions
      _showErrorDialog(
          'Error', 'An unexpected error occurred. Please try again later.');
      print('Unexpected error submitting part: $genericException');
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Add New Part'),
    ),
    body: SingleChildScrollView( // Ensures entire form is scrollable
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _partNameController,
            decoration: const InputDecoration(labelText: 'Part Name'),
          ),
          TextField(
            controller: _partNumberController,
            decoration: InputDecoration(
              labelText: 'Part Number',
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _scanPartNumber,
              ),
            ),
          ),
          TextField(
            controller: _supplierController,
            decoration: const InputDecoration(labelText: 'Supplier'),
          ),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          ExpansionTile(
            title: const Text('Select Location'),
            children: [
              SizedBox(
                height: 200, // Adjust size as needed
                child: LocationTreeView(
                  onLocationSelected: _onLocationSelected,
                ),
              ),
            ],
          ),
          if (_imagePath != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Image.file(File(_imagePath!), fit: BoxFit.cover),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _imagePath = null),
                ),
              ],
            ),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Add Part'),
          ),
          ElevatedButton(
            onPressed: _navigateAndCaptureImage,
            child: const Text('Take Picture'),
          ),
        ],
      ),
    ),
  );
}

}
