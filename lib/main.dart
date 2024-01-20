import 'package:basic_websocket/ui/styles.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'utils/websocket.dart'; // Adjust the import path to match your project structure
import 'ui/add_parts/add_parts.dart'; // Adjust the import path as needed
import 'ui/search.dart'; // Adjust the import path as needed
import 'ui/settings.dart';
import 'ui/status_bar.dart';
import 'dart:convert';
import 'utils/fade_route.dart';
import 'package:provider/provider.dart';
import 'package:basic_websocket/ui/InvenBarChart.dart';
import 'package:basic_websocket/ui/locations.dart'; // Ensure this import is correct

void main() {
  runApp(
    const IvenScanner(),
  );
}
import 'package:basic_websocket/ui/locations.dart'; // Adjust the import path as needed

class IvenScanner extends StatelessWidget {
  const IvenScanner({Key? key}) : super(key: key);

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

  const MyInvenScan({Key? key, required this.title}) : super(key: key);

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
    webSocketManager = WebSocketManager(); // Initialize WebSocketManager
    webSocketManager.addOnReceiveHandler(handleOnReceive);
    webSocketManager.addOnConnectionChangedHandler(_onConnectionChanged);
    webSocketManager.startConnection();
    _fetchStatistics();
  }

  void _fetchStatistics() async {
    var counts = await ServerApi.getCounts();

    setState(() {
      totalParts = counts['parts'];
      totalLocations = counts['locations'];
      totalCategories = counts['categories'];
    });
  }

  void handleOnReceive(dynamic data) {
    // Process data received from WebSocket
    // Implement your logic here
    print("Data from the server in InvenScan : $data");
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

Widget _buildStatCard(String title, int count, IconData icon, Color color) {
  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(
        count.toString(),
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
      ),
      onTap: title == "Locations" ? () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationsScreen()));
      } : null,
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
              leading: const Icon(Icons.add_box), // Icon for 'Add Parts'
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
              leading: const Icon(Icons.search), // Icon for 'Search'
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
              leading: const Icon(Icons.settings), // Icon for 'Settings'
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
        onTap: () {
          if (title == "Locations") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LocationsScreen()),
            );
          }
        },
      ),
       body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard("Parts", totalParts, Icons.inventory_2, Colors.blue),
          _buildStatCard("Locations", totalLocations, Icons.location_on, Colors.green),
          _buildStatCard("Categories", totalCategories, Icons.category, Colors.orange),
        ],
      ),
    ),
      bottomNavigationBar: StatusBar(webSocketManager: webSocketManager),
    );
  }
}
