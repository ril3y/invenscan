import 'package:basic_websocket/scanner_service.dart';
import 'package:basic_websocket/utils/api/server_api_exception.dart';
import 'package:flutter/material.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/utils/api/location.dart';
import 'package:basic_websocket/utils/camera_capture.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:basic_websocket/utils/api/partmodel.dart';

class AddPartForm extends StatefulWidget {
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
  List<Location> _locations = [];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadLocations(); // Call _loadLocations to fetch and set the locations
  }

  Future<void> _takePicture() async {
    if (!_camera!.value.isInitialized) {
      print('Error: Camera not initialized');
      return;
    }
    if (_camera!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }
    try {
      // Attempt to take a picture and get the file `imagePath` where it was saved.
      final image = await _camera!.takePicture();
      setState(() {
        _imagePath = image.path;
      });
    } catch (e) {
      print(e);
      return;
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

  void _loadLocations() async {
    _locations = await ServerApi.fetchLocations();
    setState(() {});
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
              child: Text('OK'),
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
          icon: Icon(Icons.qr_code_scanner),
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


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Add New Part'),
    ),
    body: SingleChildScrollView(
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
                icon: Icon(Icons.qr_code_scanner),
                onPressed: _scanPartNumber,  // Use the scanning method here
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ], // Accepts only numbers
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          DropdownButtonFormField<Location>(
            value: _selectedLocation,
            onChanged: (Location? newValue) {
              setState(() {
                _selectedLocation = newValue;
              });
            },
            items: _locations
                .map<DropdownMenuItem<Location>>((Location location) {
              return DropdownMenuItem<Location>(
                value: location,
                child: Text(location.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Add Part'),
          ),
          ElevatedButton(
            onPressed: _takePicture,
            child: const Text('Take Picture'),
          ),
          if (_imagePath != null)
            Image.file(File(_imagePath!)),
        ],
      ),
    ),
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
}
