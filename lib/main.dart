// ignore_for_file: prefer_const_constructors

import 'package:invenscan/ui/part_page.dart';
import 'package:invenscan/ui/styles.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'utils/websocket.dart';
import 'ui/add_parts/add_parts.dart';
import 'ui/search.dart';
import 'ui/settings.dart';
import 'ui/status_bar.dart';
import 'utils/fade_route.dart';
import 'package:invenscan/ui/locations.dart';

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

  @override
  void initState() {
    super.initState();
    try {
      webSocketManager = WebSocketManager();
      webSocketManager.addHandler("main", handleOnReceive, "onReceiveHandlers");
      webSocketManager.addHandler("main", _onConnectionChanged, "onConnectionChangedHandlers");
      webSocketManager.startConnection();
      _fetchStatistics();
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
    webSocketManager.removeHandler("main", "onReceiveHandlers");
    webSocketManager.removeHandler("main", "onConnectionChangedHandlers");
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
    webSocketManager
        .stopConnection();
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

  void _onConnectionChanged(bool isConnected) {
    setState(() {});
    if (!isConnected) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            isConnected
                ? AppStyles.successSnackBar('Connection successful!')
                : AppStyles.errorSnackBar('Disconnected!'),
          );
        });
      }
    }
  }

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
            onPressed: () =>
                Navigator.of(context).pop(), 
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
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      LocationsWidget()));
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StatusBar(webSocketManager: webSocketManager),
    );
  }
}
