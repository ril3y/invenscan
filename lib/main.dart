// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:basic_websocket/ui/styles.dart';
import 'package:basic_websocket/utils/nfc_manager.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scanner_service.dart';
import 'part_data.dart';
import 'package:uuid/uuid.dart';
import 'ui/settings.dart';
import 'dart:math';
import '../utils/websocket.dart';
import 'ui/heartbeat.dart';
import 'ui/status_bar.dart';
import 'dart:convert';
import 'input_dialog.dart';
import 'dart:developer' as dev;
import 'ui/question_dialog.dart';

void main() {
  runApp(const IvenScanner());
}

class IvenScanner extends StatelessWidget {
  const IvenScanner({super.key});

  @override
  Widget build(BuildContext context) {
    Random random = Random();
    // Generate a random ARGB color
    Color randomSeedColor = Color.fromARGB(
      255, // Alpha value
      random.nextInt(256), // Red value
      random.nextInt(256), // Green value
      random.nextInt(256), // Blue value
    );

    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: randomSeedColor),
        useMaterial3: true,
      ),
      home: const MyInvenScan(title: 'InvenScan'),
    );
  }
}

class MyInvenScan extends StatefulWidget {
  final String title;

  const MyInvenScan({Key? key, required this.title}) : super(key: key);

  @override
  State<MyInvenScan> createState() => _MyInvenScan();
}

class _MyInvenScan extends State<MyInvenScan> {
  String randomUuid = const Uuid().v4();
  final ScannerService _scannerService = ScannerService();
  String _scanResult = '';
  late String connection_status = "Disconnected";
  late WebSocketManager webSocketManager;
  List<PartData> parts = [];

  late bool isConnected = false; // To track WebSocket connection status
  late bool isHeartbeatReceived = false; // To track heartbeat reception

  @override
  void initState() {
    super.initState();
    webSocketManager = WebSocketManager();
// Set the callback functions
    webSocketManager.addOnError(handleOnError);
    webSocketManager.addOnConnectionChangedHandler(handleOnConnectionChanged);
    webSocketManager.addOnReceiveHandler(handleOnReceive);
    webSocketManager.addOnDisconnectHandler(handleOnDisconnect);
    webSocketManager.addOnUserInputRequired(handleOnRequiredInput);

    webSocketManager.startConnection();
  }

  void handleOnError(String error) {
    print("Error occurred: $error");
    // Additional error handling logic here
  }

  void handleOnConnectionChanged(bool isConnected) {
    print(
        "Connection status changed: ${isConnected ? 'Connected' : 'Disconnected'}");
    // Additional connection status handling logic here
  }

  void handleServerQuestions(String data) async {
    bool? userResponse = await showQuestionDialog(data);
    // Create a JSON string based on the user response
    String responseJson =
        jsonEncode({"answer": userResponse == true ? "yes" : "no"});

    if (userResponse == true) {
      webSocketManager.send(responseJson);
    }
  }

  void handleOnRequiredInput(dynamic data) async {
    try {
      var decodedData = jsonDecode(data);
      if (decodedData.containsKey('event')) {
        if (decodedData['event'] == 'question') {
          handleServerQuestions(data);
        }
      } else if (decodedData.containsKey('part_number') &&
          decodedData.containsKey('required_inputs') &&
          decodedData.containsKey('client_id')) {
        // Create a new JSON structure that includes both required_inputs and part_number
        Map<String, dynamic> dialogData = {
          'required_inputs': decodedData['required_inputs'],
          'part_number': decodedData['part_number']
        };
        String dialogJsonData = jsonEncode(dialogData);

        // Show the InputDialog with the new JSON data
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return InputDialog(
              jsonData: dialogJsonData,
              webSocketManager: webSocketManager,
            );
          },
        );
      }
    } catch (e) {
      print('Error parsing data: $e');
    }
  }

  void handleOnReceive(dynamic data) {

    try {} catch (e) {
      print('Error  in handleOnRecieve data main.dart: $e');
    }
  }

  void handleOnDisconnect() {
    print("Disconnected from WebSocket");
    // Additional disconnect handling logic here
  }

  void updateConnectionStatus(bool status) {
    setState(() {
      isConnected = status;
    });
  }

  void onDisconnect() {
    AppStyles.errorSnackBar("Disconnected");
    print("Disconnected");
  }

  Future<bool?> showQuestionDialog(String json_string) async {
    String jsonData = json_string;
    bool? response = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return QuestionsDialog(jsonData: jsonData);
      },
    );
    return response; // Return the response
  }

  void _initiateScan() async {
    try {
      _scanResult = "";
      List<int> barcodeData = await _scannerService.scan();

      // Base64 encode the QR code data
      String base64EncodedData = base64.encode(barcodeData);

      // Create the JSON object
      Map<String, dynamic> dataToSend = {
        'clientId': randomUuid,
        'qrData': base64EncodedData,
      };

      // Fetch promptNFCValue from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool promptNFCValue = prefs.getBool('prompt_nfc') ?? false;

      // Check if we need to show NFC question and await NFC scan
      if (promptNFCValue) {
        String nfcQuestionJson =
            '{"event": "question", "data": {"questionType": "regular", "questionText": "Do you want to write the part number to an NFC tag?", "positiveResponseText": "Yes", "negativeResponseText": "No"}}';

        bool? userResponse = await showQuestionDialog(nfcQuestionJson);

        // If user responded 'Yes', trigger and await NFC scan
        if (userResponse == true) {
          try {
            // Uint8List? nfcData = await NFCManager.readFromNFC();
            await NFCManager.writeToNFC("A......................");

            // Process NFC data here, if needed
            // You can include NFC data in 'dataToSend' if required
            //print(nfcData);
          } catch (e) {
            // Handle NFC read errors
            print("NFC Read Error: ${e.toString()}");
            return; // Exit the method if NFC read fails
          }
        }
      }

      // Convert the JSON object to a string
      String jsonData = json.encode(dataToSend);

      // Send the JSON string to the WebSocket
      webSocketManager.send(jsonData);

      setState(() {});
    } catch (e) {
      setState(() {
        _scanResult = 'Error: ${e.toString()}';
      });
    }
  }

  void _clear_parts() {
    webSocketManager.loadSettingsAndConnect();
    setState(() {
      parts.clear();
    });
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    SettingsScreen(webSocketManager: webSocketManager),
              ));
            },
          ),
          HeartbeatIcon(webSocketManager: webSocketManager),
        ],
      ),
      body: SingleChildScrollView(
        // Allows vertical scrolling
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('QR Code Data:'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _scanResult,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              SingleChildScrollView(
                // Add this for horizontal scrolling of DataTable
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: PartData.createColumns(parts),
                  rows: PartData.createRows(parts),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'scanButton', // Unique tag
              onPressed: _initiateScan,
              tooltip: 'Scan',
              child: const Icon(Icons.qr_code),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              heroTag: 'clearButton', // Unique tag
              onPressed: _clear_parts,
              tooltip: 'Clear Parts',
              child: const Icon(Icons.clear),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              heroTag: 'addPartButton', // Unique tag
              onPressed: () {
                print(showQuestionDialog(
                    '{"event": "question", "data": {"questionType": "regular", "questionText": "Do you want to write the part number to an NFC tag?", "positiveResponseText": "Yes", "negativeResponseText": "No"}}'));
              },
              tooltip: 'Add Part',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StatusBar(webSocketManager: webSocketManager),
    );
  }
}
