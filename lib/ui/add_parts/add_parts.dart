import 'dart:convert';
import 'package:basic_websocket/ui/add_parts/edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:basic_websocket/scanner_service.dart';
import 'package:basic_websocket/part_data.dart';
import 'package:basic_websocket/utils/websocket.dart';
import 'package:basic_websocket/input_dialog.dart';
import 'package:basic_websocket/ui/question_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:basic_websocket/utils/nfc_manager.dart';
import 'package:basic_websocket/ui/status_bar.dart';
import 'package:basic_websocket/ui/add_parts/add_part_form.dart';

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
                setState(() {
                  isWritingToNfc = false;
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.webSocketManager.addOnUserInputRequired(handleOnRequiredInput);
    widget.webSocketManager.addOnPartAddedHandler(handleOnPartAdded);
    widget.webSocketManager.startConnection();
  }

  void handleOnReceive(dynamic data) {
    // Process data received from WebSocket
    // Implement your logic here
    print("Part Added : $data");
    var decodedData = jsonDecode(data);

    setState(() {
      parts.add(PartData.fromJson(
          decodedData['data'])); // Add the new part to the list
    });
  }

  void handleOnPartAdded(dynamic jsonData) async {
    // Assuming jsonData is a Map<String, dynamic> as received from WebSocket
    if (jsonData != null && jsonData['event'] == 'part_added') {
      // Extract the part data
      Map<String, dynamic> partData = jsonData['data'];

      // Check if partData is not null and has the expected structure
      // Add the new part to the list and update UI
      setState(() {
        parts.add(PartData.fromJson(partData));
      });

      // Handle NFC writing if required
      bool nfcWriteSuccess = await _handleNFCScan(partData);
      if (nfcWriteSuccess) {
        // NFC write was successful
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC Tag Written Successfully!')));
      } else {
        // NFC write failed or was not performed
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC Tag Writing Skipped.')));
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
      setState(() {
        _scanResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<bool> _handleNFCScan(Map<String, dynamic> dataToSend) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool promptNFCValue = prefs.getBool('prompt_nfc') ?? false;

    if (promptNFCValue) {
      bool? userResponse = await showQuestionDialog(
          '{"event": "question", "question_type": "regular", "question_text": "Do you want to write the part number to an NFC tag?", "positive_text": "Yes", "negative_text": "No"}');

      if (userResponse == true) {
        setState(() {
          isWritingToNfc = true;
        });
        showNfcWaitingDialog(); // Display the waiting dialog

        try {
          await NFCManager.writeToNFC(dataToSend['uuid']);
          Navigator.of(context)
              .pop(); // Close the dialog immediately after NFC write
          return true; // Return true if NFC write was successful
        } catch (e) {
          Navigator.of(context).pop(); // Close the dialog in case of an error
          // Handle the error
          return false; // Return false if NFC write failed
        } finally {
          if (mounted) {
            setState(() {
              isWritingToNfc = false;
            });
          }
        }
      }
    }

    return false; // Return false by default
  }

  void _clear_parts() {
    setState(() {
      parts.clear();
    });
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

 void handleOnRequiredInput(dynamic data) async {
  var decodedData = jsonDecode(data);

  if (decodedData.containsKey('required_inputs')) {
    // Handle required inputs
    if (!mounted) return;
    showInputQuestionDialog(decodedData);
  } else if (decodedData.containsKey('event') &&
      decodedData['event'] == "question") {
    // Early return if the widget is not in the tree
    if (!mounted) return;

    bool? userResponse = await showQuestionDialog(data);
    // Re-check if the widget is still mounted after awaiting
    if (!mounted) return;

    // Check if a response was received
    if (userResponse != null) {
      // Check the value of userResponse and send the corresponding message
      String response = userResponse ? "yes" : "no";
      widget.webSocketManager.send(response);
    }
  }
}


  void _editPart(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPartScreen(part: parts[index]),
      ),
    );
  }

  void _navigateToEditPartScreen(PartData part) {
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
              DataTable(
                columns: PartData.createColumns(),
                rows: PartData.createRows(parts, _navigateToEditPartScreen),
              ),
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

  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'scanButton',
            onPressed: _initiateScan,
            tooltip: 'Scan',
            child: const Icon(Icons.qr_code),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'addManualPartButton',
            onPressed: _navigateToAddPartForm,
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
