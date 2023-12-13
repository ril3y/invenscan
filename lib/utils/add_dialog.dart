import 'package:flutter/material.dart';

class AddDialog extends StatefulWidget {
  final String category;
  final Future<void> Function() onDataFetch; // Callback function
  final List<String> userInputRequirements;

  const AddDialog({
    Key? key,
    this.category = '',
    required this.onDataFetch, required this.userInputRequirements, // Pass the parser instance
  }) : super(key: key);

  @override
  _AddDialogState createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  final bool _isLoading = false;
  dynamic _part;
  String? _imageUrl; // Define a variable to hold the imageUrl
  String? _description; // Define a variable to hold the imageUrl

  @override
  void initState() {
    super.initState();
    for (var requirement in widget.userInputRequirements) {
      _controllers[requirement] = TextEditingController();
    }
    // _fetchPartData();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
  }