import 'package:basic_websocket/ui/styles.dart';
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

void main() {
  runApp(
       const IvenScanner(),
  );
}

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
  String msg = "Hello";

  @override
  void initState() {
    super.initState();
    webSocketManager = WebSocketManager(); // Initialize WebSocketManager
    webSocketManager.addOnReceiveHandler(handleOnReceive);
    webSocketManager.addOnConnectionChangedHandler(_onConnectionChanged);
    webSocketManager.startConnection();
  }

  void handleOnReceive(dynamic data) {
    // Process data received from WebSocket
    // Implement your logic here
    print("Data from the server in InvenScan : $data");
  }

  void _onConnectionChanged(bool isConnected) {
    setState(() {
          msg = isConnected ?  'Connect' :'Disconnect';

    });
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
                    FadeRoute(
                        page: AddParts(webSocketManager: webSocketManager)),
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
                        page:
                            SettingsScreen(webSocketManager: webSocketManager)),
                  );
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: Text(msg),
        ),
        bottomNavigationBar: StatusBar(webSocketManager: webSocketManager),
      );
    }
  }