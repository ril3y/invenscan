import 'package:flutter/material.dart';
import 'utils/user_input_requirement.dart';
import 'category_type_associations.dart';
import 'utils/barcode_parser.dart';
import 'dart:convert';

class InputDialog extends StatefulWidget {
  final List<UserInputRequirement> userInputRequirements;
  final String category;
  final BarcodeParser barcodeParser;
  final Future<void> Function() onDataFetch; // Callback function

  const InputDialog({
    Key? key,
    required this.userInputRequirements,
    this.category = '',
    required this.barcodeParser,
    required this.onDataFetch, // Pass the parser instance
  }) : super(key: key);

  @override
  _InputDialogState createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;
  dynamic _part;
  String? _imageUrl; // Define a variable to hold the imageUrl
  String? _description; // Define a variable to hold the imageUrl

  @override
  void initState() {
    super.initState();
    for (var requirement in widget.userInputRequirements) {
      _controllers[requirement.name] = TextEditingController();
    }
    _fetchPartData();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _fetchPartData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _part = await widget.barcodeParser.enrich();
      if (_part != null && _part.partType != null) {
        setState(() {
          _controllers['type']?.text = _part.partType;

          // Check if _part.imageURL is not null before assigning it to _imageUrl
          if (_part.imageURL != null) {
            _imageUrl = _part.imageURL;
          }

          if (_part.description != null) {
            _controllers['description']?.text = _part.description;
          }
        });
      }
    } catch (e) {
      // Handle errors
      print('Error fetching part data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEditableDropdown(UserInputRequirement requirement) {
    var types = CategoryTypeAssociations.getTypesForCategory(widget.category);
    var controller = _controllers[requirement.name]!;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: requirement.name),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter or select a ${requirement.name}';
              }
              return null;
            },
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (String value) {
            setState(() {
              controller.text = value;
              _formData[requirement.name] = value;
            });
          },
          itemBuilder: (BuildContext context) {
            return types.map<PopupMenuItem<String>>((String value) {
              return PopupMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  Widget _buildFormField(UserInputRequirement requirement) {
    if (requirement.name == 'type' && widget.category.isNotEmpty) {
      return _buildEditableDropdown(requirement);
    } else {
      var controller = _controllers[requirement.name]!;
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: requirement.name),
        keyboardType:
            requirement.type == int ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter ${requirement.name}';
          }
          return null;
        },
      );
    }
  }

  List<Widget> _buildAdditionalProperties() {
    List<Widget> widgets = [];
    if (_part != null) {
      _part.additionalProperties.forEach((key, value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  '$key: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Adjust the font size as needed
                    color: Colors.black, // Text color
                  ),
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16, // Adjust the font size as needed
                    color: Colors.black, // Text color
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          if (_imageUrl != null) // Check if imageUrl is available
            Image.network(_imageUrl!), // Use the imageUrl here'

          const Text('Enter Required Data'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.userInputRequirements.map(_buildFormField).toList(),
              ..._buildAdditionalProperties(),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (_isLoading) const CircularProgressIndicator(),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: const Text('Submit'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              // Merge _part.toMap() into _formData
              _formData.addAll(_part.toMap());

              Navigator.of(context).pop({
                'part_data': jsonEncode(_formData),
              });
            }
          },
        ),
      ],
    );
  }
}
