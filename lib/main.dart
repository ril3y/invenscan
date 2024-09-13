// ignore_for_file: prefer_const_constructors

import 'package:invenscan/ui/part_page.dart';
import 'package:invenscan/ui/styles.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invenscan/utils/nfc_manager.dart';
import 'dart:math';
import 'utils/websocket.dart';
import 'ui/add_parts/add_parts.dart';
import 'ui/search.dart';
import 'ui/settings.dart';
import 'ui/status_bar.dart';
import 'utils/fade_route.dart';
import 'package:invenscan/ui/locations.dart';
import 'dart:convert';

void main() {
  runApp(
    const IvenScanner(),
  );
}

class IvenScanner extends StatelessWidget {
  const IvenScanner({super.key});

  @override
  Widget build(BuildContext context) {
    Random random = Random();
    Color randomSeedColor = Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );

    return MaterialApp(
      title: 'InvenScan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: randomSeedColor),
        primarySwatch: Colors.blue,
      ),
      home: const MyInvenScan(title: 'InvenScan'),
    );
  }
}

class MyInvenScan extends StatefulWidget {
  final String title;

  const MyInvenScan({super.key, required this.title});

  @override
  State<MyInvenScan> createState() => _MyInvenScanState();
}

class _MyInvenScanState extends State<MyInvenScan> {
  late WebSocketManager webSocketManager;
  int totalParts = 0;
  int totalLocations = 0;
  int totalCategories = 0;

  bool isWaitingForNFC = false;
  @override
  void initState() {
    super.initState();
    try {
      webSocketManager = WebSocketManager();
      webSocketManager.addHandler("main", handleOnReceive, "onReceiveHandlers");
      // webSocketManager.addHandler("main", _onConnectionChanged, "onConnectionChangedHandlers");
      webSocketManager.startConnection();

      if (webSocketManager.checkConnectionStatus()) {
        _fetchStatistics();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      onError('Failed to connect to WebSocket.');
    }
  }

  @override
  void dispose() {
    super.dispose();
    // webSocketManager.removeHandler("main", "onReceiveHandlers");
    // webSocketManager.removeHandler("main", "onConnectionChangedHandlers");
  }

  void onError(String message) {
    // Call this method when an error occurs
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialogError(
            context, message, 'Connection Error', _navigateToSettings);
      });
    }
  }

  void _restartConnection() {
    webSocketManager.stopConnection();
    webSocketManager.startConnection();
  }

  void _fetchStatistics() async {
    try {
      var counts = await ServerApi.getCounts();
      setState(() {
        totalParts = counts['parts'];
        totalLocations = counts['locations'];
        totalCategories = counts['categories'];
      });
    } catch (e) {
      // Log error or handle it as needed
      if (kDebugMode) {
        print("Error fetching statistics: $e");
      }
      // Show error dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialogError(
            context,
            'Unable to fetch statistics. Please check your server settings.',
            'Server Error',
            _navigateToSettings);
      });
    }
  }

  void handleOnReceive(dynamic data) {
    if (kDebugMode) {
      print("Data from the server in InvenScan : $data");
    }
  }

  // void _onConnectionChanged(bool isConnected) {

  //   setState(() {});
  //   if (!isConnected) {
  //     if (mounted) {

  //       initState();
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           isConnected
  //               ? AppStyles.successSnackBar('Connection successful!')
  //               : AppStyles.errorSnackBar('Disconnected!'),
  //         );
  //       });
  //     }
  //   }
  // }

  void showDialogError(BuildContext context, String message, String title,
      VoidCallback callback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              _restartConnection(); // Attempt to restart the WebSocket connection
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              callback(); // Navigate to settings or perform another callback action
            },
            child: Text('Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SettingsScreen(webSocketManager: webSocketManager)),
    );
  }

  void _handleNfcData(Uint8List nfcData) {
    try {
      setState(() {
        String data = utf8.decode(nfcData);
        String jsonString = data.substring(3).trim();
        final jsonData = jsonDecode(jsonString);
        isWaitingForNFC = false;
        Navigator.push(
          context,
          FadeRoute(page: const SearchScreen()),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing NFC data: ${e.toString()}')),
        );
      }
    }
  }

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
                    isWaitingForNFC = false;
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

  Widget _buildNfcReadCard() {
  return GestureDetector(
    onTap: () async {
      // Show the NFC waiting dialog
      showNfcWaitingDialog();

      try {
        // Await the Future to get the actual data
        Uint8List? nfcData = await NFCManager.readFromNFC();

        // Dismiss the waiting dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (nfcData != null) {
          _handleNfcData(nfcData);
        } else {
          // Handle the case where NFC data is null (e.g., no data read from the tag)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No data read from NFC tag.')),
          );
        }
      } catch (e) {
        // Dismiss the waiting dialog in case of an error
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Handle any errors that occur during NFC reading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read NFC tag: ${e.toString()}')),
        );
      }
    },
    child: Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(Icons.nfc, color: Colors.blue),
        title: Text('Scan NFC Tag', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward, color: Colors.blue),
      ),
    ),
  );
}


  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return GestureDetector(
      onLongPress: () {
        // Call the method to fetch statistics when the button is held down
        _fetchStatistics();
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            count.toString(),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          onTap: () {
            // Differentiate navigation based on the title of the card
            if (title == "Parts") {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => PartPage()));
            } else if (title == "Locations") {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => LocationsWidget()));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Parts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  FadeRoute(page: AddParts(webSocketManager: webSocketManager)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  FadeRoute(page: const SearchScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  FadeRoute(
                      page: SettingsScreen(webSocketManager: webSocketManager)),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchStatistics(); // This is the method you want to call on swipe down
        },
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(), // Ensures the refresh indicator works even if content is not overflowing
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                    "Parts", totalParts, Icons.inventory_2, Colors.blue),
                _buildStatCard("Locations", totalLocations, Icons.location_on,
                    Colors.green),
                _buildStatCard("Categories", totalCategories, Icons.category,
                    Colors.orange),
                _buildNfcReadCard(), // Add the NFC read card here
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StatusBar(webSocketManager: webSocketManager),
    );
  }
}
