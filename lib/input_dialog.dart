// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import 'dart:convert';
import 'utils/websocket.dart';

class InputDialog extends StatefulWidget {
  final String jsonData; // Pass the JSON string here
  final WebSocketManager webSocketManager;

  const InputDialog({
    super.key,
    required this.jsonData,
    required this.webSocketManager,
  });

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late List<dynamic> requiredInputs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  late String partNumber; // Variable to store part number

  @override
  void initState() {
    super.initState();
    _parseJsonData();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Gather data from the controllers
      Map<String, dynamic> userInputData = {};
      _controllers.forEach((fieldName, controller) {
        userInputData[fieldName] = controller.text;
      });

      // Decode the JSON data which is expected to be a Map
      Map<String, dynamic> originalJson = jsonDecode(widget.jsonData);
      List<dynamic> originalJsonList = originalJson['required_inputs'] ?? [];

      // Iterate through the list and update the 'value' of each field
      for (var field in originalJsonList) {
        if (field is Map<String, dynamic> && field.containsKey('field_name')) {
          String fieldName = field['field_name'];
          if (userInputData.containsKey(fieldName)) {
            field['value'] = userInputData[fieldName]; // Update the 'value'
          }
        }
      }

      // Update the list in the original map
      originalJson['required_inputs'] = originalJsonList;

      // Convert the updated map to a JSON string
      String updatedJsonString = jsonEncode(originalJson);

      // Send the updated JSON string back to the server
      widget.webSocketManager.send(updatedJsonString);

      // Close the dialog or navigate away as needed
      Navigator.of(context).pop();
    }
  }

  void _parseJsonData() {
    try {
      Map<String, dynamic> fullData = jsonDecode(widget.jsonData);
      if (fullData.containsKey('required_inputs') &&
          fullData['required_inputs'] is List) {
        requiredInputs = fullData['required_inputs'];
      } else {
        requiredInputs = [];
        print('Error: required_inputs is not a list.');
      }

      if (fullData.containsKey('part_number')) {
        partNumber = fullData['part_number'];
      } else {
        print('Error: part_number is missing.');
      }

      // Initialize controllers for each input requirement
      for (var input in requiredInputs) {
        if (input is Map<String, dynamic> && input.containsKey('field_name')) {
          _controllers[input['field_name']] = TextEditingController();
        }
      }
    } catch (e) {
      print('Error parsing JSON data: $e');
      requiredInputs = [];
      partNumber =
          ''; // Initialize partNumber to an empty string or a default value
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildFormField(Map<String, dynamic> input) {
    var controller = _controllers[input['field_name']]!;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: input['prompt']),
      keyboardType: input['data_type'] == 'int'
          ? TextInputType.number
          : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${input['field_name']}';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Required Data'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: requiredInputs
                .map<Widget>((input) => _buildFormField(input))
                .toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          onPressed: _handleSubmit,
          child: const Text('Submit'), // Reference to your _handleSubmit function
        ),
      ],
    );
  }
}
