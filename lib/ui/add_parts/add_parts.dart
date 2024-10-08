// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invenscan/input_dialog.dart';
import 'package:invenscan/part_data.dart';
import 'package:invenscan/scanner_service.dart';
import 'package:invenscan/ui/add_parts/add_part_form.dart';
import 'package:invenscan/ui/add_parts/edit_screen.dart';
import 'package:invenscan/ui/add_parts/view_part.dart';
import 'package:invenscan/ui/question_dialog.dart';
import 'package:invenscan/ui/status_bar.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:invenscan/utils/nfc_manager.dart';
import 'package:invenscan/utils/websocket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AddParts extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const AddParts({super.key, required this.webSocketManager});

  @override
  _AddPartsState createState() => _AddPartsState();
}

class _AddPartsState extends State<AddParts> {
  String randomUuid = const Uuid().v4();
  final ScannerService _scannerService = ScannerService();
  String _scanResult = '';
  List<PartData> parts = [];
  bool isWritingToNfc = false;
  late String serverUrl;

  // Add these fields
  bool _qrButtonEnabled = false;
  bool _addButtonEnabled = false;

  void showNfcWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Waiting for NFC Tag'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Please bring the NFC tag close to the device.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cancel the NFC write operation
                if (mounted) {
                  // Check if the widget is still in the widget tree
                  setState(() {
                    isWritingToNfc = false;
                  });
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  //   'onErrorHandlers': onErrorHandlers,
  // 'onConnectionChangedHandlers': onConnectionChangedHandlers,
  // 'onReceiveHandlers': onReceiveHandlers,
  // 'onHeartBeatHandlers': onHeartBeatHandlers.map((key, value) => MapEntry(key, () => value())),
  // 'onUserInputRequiredHandlers': onUserInputRequiredHandlers,
  // 'onConnectionFailureHandlers': onConnectionFailureHandlers,
  // 'onPartAddedHandlers': onPartAddedHandlers,

  @override
  void initState() {
    super.initState();

    widget.webSocketManager.addHandler(
        "add_parts", handleInput, "onUserInputRequiredHandlers");

    widget.webSocketManager
        .addHandler("add_parts", handleOnPartAdded, "onPartAddedHandlers");
    widget.webSocketManager.addHandler(
        "add_parts", handleOnConnectionChanged, "onConnectionChangedHandlers");

    widget.webSocketManager.startConnection();
    if (widget.webSocketManager.isConnected) {
      handleOnConnectionChanged(true);
    }
  }

  void handleOnConnectionChanged(bool isConnected) {
    _qrButtonEnabled = isConnected;
    _addButtonEnabled = isConnected;
    if (mounted) {
      setState() {
        _qrButtonEnabled = isConnected;
        _addButtonEnabled = isConnected;
      }
    }
  }

  @override
  void dispose() {
    // print("We are disposing this object");
    // // Remove all handlers before adding new ones
    // widget.webSocketManager
    //     .removeHandler("add_parts", "onUserInputRequiredHandlers");
    // widget.webSocketManager.removeHandler("add_parts", "onPartAddedHandlers");
    super.dispose();
  }

  void handleOnReceive(dynamic data) {
    // Process data received from WebSocket
    // Implement your logic here
    if (kDebugMode) {
      print("Part Added : $data");
    }
    var decodedData = jsonDecode(data);

    if (mounted) {
      setState(() {
        parts.add(PartData.fromJson(
            decodedData['data'])); // Add the new part to the list
      });
    }
  }

  void handleOnPartAdded(dynamic jsonData) async {
    // Assuming jsonData is a Map<String, dynamic> as received from WebSocket
    if (jsonData != null && jsonData['event'] == 'part_added') {
      // Extract the part data
      Map<String, dynamic> partData = jsonData['data'];

      // Perform any asynchronous work before calling setState()
      bool nfcWriteSuccess = await _handleNFCScan(partData);

      // Now, use setState() to update the UI synchronously
      if (mounted) {
        setState(() {
          // Add the new part to the list
          parts.add(PartData.fromJson(partData));
          // You might want to update other parts of your UI based on NFC write success here
        });

        // Show a SnackBar based on the outcome of the NFC write operation
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(nfcWriteSuccess
                ? 'NFC Tag Written Successfully!'
                : 'NFC Tag Writing Skipped.')));

                ServerApi.getCounts();
                // Open the newly created part in the view_part screen
                PartModel newPart = PartModel.fromJson(partData);
                _navigateToViewPart(newPart);
      }
    } else {
      // Handle case where jsonData does not contain the expected event
      print("Error: Unexpected jsonData structure or event type.");
    }
  }

  Future<bool?> showQuestionDialog(String jsonString) async {
    String jsonData = jsonString;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return QuestionsDialog(jsonData: jsonData);
      },
    );
  }

  void _initiateScan() async {
    try {
      List<int> barcodeData = await _scannerService.scanBarcode();
      String base64EncodedData = base64.encode(barcodeData);
      Map<String, dynamic> dataToSend = {
        'clientId': randomUuid,
        'qrData': base64EncodedData,
      };

      widget.webSocketManager.send(json.encode(dataToSend));
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanResult = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<bool> _handleNFCScan(Map<String, dynamic> dataToSend) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool promptNFCValue = prefs.getBool('prompt_nfc') ?? false;

    if (promptNFCValue) {
      bool? userResponse;
      // Ensure the widget is still mounted before attempting to show a dialog.
      if (mounted) {
        userResponse = await showQuestionDialog(
            '{"event": "question", "question_type": "regular", "question_text": "Do you want to write the part number to an NFC tag?", "positive_text": "Yes", "negative_text": "No"}');
      }

      // Check if the user agreed to proceed after the dialog.
      if (userResponse == true) {
        setState(() {
          isWritingToNfc = true;
        });

        showNfcWaitingDialog(); // Display waiting dialog

        try {
          // Initialize an empty map for the NFC data
          Map<String, dynamic> nfcData = {};

          // Always include part_id
          nfcData['part_id'] = dataToSend['part_id'];

          // Check and include part_name and part_number if they exist
          if (dataToSend.containsKey('part_name')) {
            nfcData['part_name'] = dataToSend['part_name'];
          }
          if (dataToSend.containsKey('part_number')) {
            nfcData['part_number'] = dataToSend['part_number'];
          }

          // Convert the map to a JSON string
          String jsonData = jsonEncode(nfcData);

          // Write the JSON string to the NFC tag
          await NFCManager.writeToNFC(jsonData);
          if (mounted) {
            Navigator.of(context).pop(); // Close waiting dialog
          }
          return true; // NFC write was successful
        } catch (e) {
          if (mounted) {
            Navigator.of(context)
                .pop(); // Close waiting dialog in case of error
          }
          // Optionally, show an error message or handle the error
          return false; // NFC write failed
        } finally {
          if (mounted) {
            setState(() {
              isWritingToNfc = false;
            });
          }
        }
      } else {
        return false; // User responded negatively or dialog was not shown
      }
    }
    return false; // Return false by default if promptNFCValue is false
  }

  void _clear_parts() {
    if (mounted) {
      setState(() {
        parts.clear();
      });
    }
  }

  void showInputQuestionDialog(Map<String, dynamic> decodedData) {
    Map<String, dynamic> dialogData = {
      'required_inputs': decodedData['required_inputs'],
      'part_number': decodedData['part_number']
    };
    String dialogJsonData = jsonEncode(dialogData);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InputDialog(
          jsonData: dialogJsonData,
          webSocketManager: widget.webSocketManager,
        );
      },
    );
  }

  void handleInput(dynamic data) async {
  var decodedData = jsonDecode(data);
  print("handle input: $decodedData");

  // Handle required inputs if present
  if (decodedData.containsKey('required_inputs')) {
    if (!mounted) return;
    showInputQuestionDialog(decodedData); // Required inputs must be handled
  }

  // Handle optional inputs if present
  else if (decodedData.containsKey('optional_inputs')) {
    if (!mounted) return;
    bool? userResponse = await showInputDialogForOptional(decodedData);
    
    // Optional inputs can be ignored based on the user's decision
    if (userResponse != null && userResponse) {
      showInputQuestionDialog(decodedData); // Handle optional inputs only if user agrees
    }
  }

  // Handle event-based questions if present
  else if (decodedData.containsKey('event') && decodedData['event'] == "question") {
    if (!mounted) return;

    bool? userResponse = await showQuestionDialog(data);
    if (!mounted) return;

    if (userResponse != null) {
      // Send "yes" or "no" based on user response
      String response = userResponse ? "yes" : "no";
      widget.webSocketManager.send(response);
    }
  }
}

Future<bool?> showInputDialogForOptional(dynamic data) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Optional Input'),
        content: const Text('Do you want to provide optional input?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Provide Input'),
          ),
        ],
      );
    },
  );
}


  // void _editPart(int index) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EditPartScreen(part: parts[index]),
  //     ),
  //   );
  // }

  void _navigateToEditPartScreen(PartModel part) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPartScreen(part: part)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Add Parts'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('QR Code Data:'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_scanResult,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              // DataTable(
              //   columns: PartData.createColumns(),
              //   rows: PartData.createRows(parts, _navigateToEditPartScreen),
              // ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      bottomNavigationBar: StatusBar(webSocketManager: widget.webSocketManager),
    );
  }

  void _navigateToAddPartForm() async {
    final response = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPartForm()),
    );




    if (response != null) {
      // Handle the response here
      handleOnPartAdded(response);
      print("Response from AddPartForm: $response");
    }
  }

  void _navigateToViewPart(PartModel part) async {
    final response = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViewPartScreen(part: part)),
    );

    if (response != null) { 
      // Handle the response here
      handleOnPartAdded(response);
      print("Response from ViewPartScreen: $response");
    }
  }



  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'scanButton',
            foregroundColor: _addButtonEnabled ? null : Colors.grey,
            onPressed: true ? _initiateScan : null,
            tooltip: 'Scan',
            child: const Icon(Icons.qr_code),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'addManualPartButton',
            foregroundColor: _addButtonEnabled ? null : Colors.grey,
            onPressed: _addButtonEnabled ? _navigateToAddPartForm : null,
            tooltip: 'Add Manual Part',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'clearButton',
            onPressed: _clear_parts,
            tooltip: 'Clear Parts',
            child: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}
