import 'package:basic_websocket/ui/styles.dart';
import 'package:flutter/material.dart';
import 'scanner_service.dart';
import 'part_data.dart';
import 'package:uuid/uuid.dart';
import 'ui/settings.dart';
import 'dart:math';
import '../utils/websocket.dart';

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

  @override
  void initState() {
    super.initState();
    webSocketManager = WebSocketManager(onReceive, onDisconnect);
  }

  void onReceive(data) {
    print("Data from main!" + data);
  }

  void onDisconnect() {
    AppStyles.errorSnackBar("Disconnected");
    print("Disconnected");
  }

  void _initiateScan() async {
    try {
      _scanResult = "";
      List<int> barcodeData = await _scannerService.scan();
      setState(() {});
    } catch (e) {
      setState(() {
        _scanResult = 'Error: ${e.toString()}';
      });
    }
  }

  void _clear_parts() {
    setState(() {
      parts.clear();
    });
  }

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
                // Add your logic to handle the "Add Part" button here
              },
              tooltip: 'Add Part',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
