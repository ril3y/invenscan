import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:convert';
import 'input_dialog.dart';
import 'scanner_service.dart';
import 'part_data.dart';
import 'package:uuid/uuid.dart';

// Import Parsers
import 'parsers/boltdepot.dart';
import 'utils/barcode_parser.dart';
import 'utils/user_input_requirement.dart';

//Create instances
BoltDepotParser boltDepotParser = BoltDepotParser();

List<BarcodeParser> parsers = [boltDepotParser];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Part Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String randomUuid = const Uuid().v4();
  final int _counter = 0;
  Uri uri = Uri.parse('ws://192.168.1.237:57891/ws');
  late WebSocketChannel channel;
  Timer? _timer; //Websocket Connection Timer
  final ScannerService _scannerService = ScannerService();
  String _scanResult = '';
  final String _parsed_part_number = "";
  final int _parsed_quantity = 0;
  final String _parsed_part_link = "";
  final String _socket_id = "";

  List<PartData> parts = [];

  List<DataColumn> _createColumns() {
    var columns = <DataColumn>[
      const DataColumn(label: Text('Supplier')),
      const DataColumn(label: Text('Part Number')),
    ];

    // Add additional columns based on dynamic data (if any)
    if (parts.isNotEmpty) {
      for (var key in parts[0].additionalData.keys) {
        columns.add(DataColumn(label: Text(key)));
      }
    }

    return columns;
  }

  List<DataRow> _createRows(List<PartData> parts) {
    return parts.map<DataRow>((PartData part) {
      var cells = <DataCell>[
        DataCell(Text(part.supplierPn)),
        DataCell(Text(part.manufacturerPn)),
      ];

      // Add cells for additional data
      part.additionalData.forEach((key, value) {
        cells.add(DataCell(Text(value.toString())));
      });

      return DataRow(cells: cells);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      uri, // Ensure uri is correctly formatted
      pingInterval: const Duration(seconds: 5),
    );
    listenWs();
  }

  // Inside your _MyHomePageState class

  void _initiateScan() async {
    try {
      _scanResult = "";
      List<int> barcodeData = await _scannerService.scan();
      setState(() {
        var parser = parseBarcodeData(barcodeData);
        if (parser != null) {
          // Example: Assuming category is determined from the parser
          String category =
              parser.categories.isNotEmpty ? parser.categories.first : '';

          // Now pass this category to the InputDialog
          _showInputDialog(parser.requiredUserInputs, category, parser);
        }
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _showInputDialog(List<UserInputRequirement> requirements,
      String category, BarcodeParser parser) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return InputDialog(
          userInputRequirements: requirements,
          category: category,
          barcodeParser: parser,
          onDataFetch: () {
            return parser.enrich();
          }, // Pass the parser instance
        );
      },
    );

    if (result != null) {
      // Send the JSON data directly as a string
      channel.sink.add(jsonEncode(result));
      print(result); // Add your logic to handle the result
    }
  }

  dynamic parseBarcodeData(List<int> barcodeData) {
    for (BarcodeParser parser in parsers) {
      if (parser.matches(barcodeData)) {
        return parser.parse(barcodeData);
      }
    }

    print("No matching parser found for the given barcode data.");
    return null;
  }

  void listenWs() {
    var timeoutDuration = const Duration(seconds: 15);
    //channel.sink.add('{"hello": "' + randomUuid + '"}');
    resetTimer() {
      _timer?.cancel();
      _timer = Timer(timeoutDuration, () {
        // Handle disconnection
        print('Connection renewed...');
      });
    }

    channel.stream.listen((data) {
      if (data == 'heartbeat') {
        print('Heartbeat received, resetting timer.');
        // Reset the timer upon receiving a heartbeat
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 10), () {
          print('Connection timed out.');
          channel.sink.close(0);
        });
      } else {
        print("other data:" + data);
        var jsonData = json.decode(data);
        setState(() {
          parts.add(PartData.fromJson(jsonData));
        });
      }

      resetTimer(); // reset the timer on every new message received
    }, onError: (error) {
      print(error);
      _timer?.cancel();
    }, onDone: () {
      print('Stream is done');
      _timer?.cancel();
    });

    resetTimer(); // start the timer when listening starts
  }

  void connectWs() async {
    try {
      channel = IOWebSocketChannel.connect(
        uri, // Ensure the URI is correct.
        pingInterval: const Duration(seconds: 1),
      );
      listenWs();
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  void _clear_parts() {
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
                  columns: _createColumns(),
                  rows: _createRows(parts),
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
              onPressed: _initiateScan,
              tooltip: 'Scan',
              child: const Icon(Icons.qr_code),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: connectWs,
              tooltip: 'Connect',
              child: const Icon(Icons.send),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _clear_parts,
              tooltip: 'Clear Parts',
              child: const Icon(Icons.clear),
            ),
          ],
        ),
      ),
    );
  }
}
