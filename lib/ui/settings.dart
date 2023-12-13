// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/websocket.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'styles.dart';

class ServerInfo {
  String name;
  String address;
  String port;
  bool isSelected;

  ServerInfo(
      {required this.name,
      required this.address,
      required this.port,
      this.isSelected = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'port': port,
        'isSelected': isSelected,
      };

  static ServerInfo fromJson(Map<String, dynamic> json) => ServerInfo(
        name: json['name'],
        address: json['address'],
        port: json['port'],
        isSelected: json['isSelected'] ?? false,
      );
}

class SettingsScreen extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const SettingsScreen({Key? key, required this.webSocketManager})
      : super(key: key);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  String _validationMessage = '';
  String _buttonText = 'Connect';
  List<ServerInfo> servers = [];
  bool _autoConnect = false;
  bool _autoReconnect = false;

// ================================================ initState() =========================================================
  @override
  void initState() {
    super.initState();
    _initializeConnectionStatus();
    _loadSavedServers();
    _loadSettings();
    widget.webSocketManager.onError = _onWebSocketError;
    widget.webSocketManager.onConnectionChanged = _onConnectionChanged;
  }
// ================================================ initState() =========================================================

  void _initializeConnectionStatus() {
    // Check the current connection status from WebSocketManager
    bool isConnected = widget.webSocketManager.isConnected;
    setState(() {
      _buttonText = isConnected ? 'Disconnect' : 'Connect';
    });
  }

  void _onConnectionChanged(bool isConnected) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          isConnected
              ? AppStyles.successSnackBar('Connection successful!')
              : AppStyles.errorSnackBar('Disconnected!'),
        );
      });
    }
    if (mounted) {
      setState(() {
        _buttonText = isConnected ? 'Disconnect' : 'Connect';
      });
    }
  }

  void _addServer() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _portController.text.isEmpty) {
      setState(() {
        _validationMessage = 'All fields are required.';
      });
      return;
    }

    ServerInfo newServer = ServerInfo(
      name: _nameController.text,
      address: _addressController.text,
      port: _portController.text,
    );

    servers.add(newServer);
    _saveServers();

    setState(() {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          AppStyles.successSnackBar('Server added successfully!'));
      // Optionally, clear the text fields after adding the server
      _nameController.clear();
      _addressController.clear();
      _portController.clear();
    });
  }

  void _saveServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedServers =
        servers.map((server) => json.encode(server.toJson())).toList();
    await prefs.setStringList('servers', storedServers);
  }

  void _removeServer(int index) {
    servers.removeAt(index);
    _saveServers();
    setState(() {
      _autoConnect = servers.any((server) => server.isSelected);
    });
  }

  void _selectServer(int index) {
    for (var i = 0; i < servers.length; i++) {
      servers[i].isSelected = i == index;
    }
    _saveSelectedServer(servers[index]);
    _saveServers();
    setState(() {
      _autoConnect = servers[index].isSelected;
    });
  }

  void _saveSelectedServer(ServerInfo server) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_server_name', server.name);
    await prefs.setString('selected_server_address', server.address);
    await prefs.setString('selected_server_port', server.port);
  }

// Future<void> _loadSettingsAndConnect() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String? serverAddress = prefs.getString('selected_server_address');
//   String? serverPort = prefs.getString('selected_server_port');
//   bool autoConnect = prefs.getBool('auto_connect') ?? false;

//   if (serverAddress != null && serverPort != null && autoConnect) {
//     String uriString = 'ws://$serverAddress:$serverPort/ws';
//     connect();
//   }
// }

  void _loadSavedServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedServers = prefs.getStringList('servers') ?? [];
    servers =
        storedServers.map((s) => ServerInfo.fromJson(json.decode(s))).toList();
    setState(() {});
  }

  void _onWebSocketError(String errorMessage) {
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );

    setState(() {
      _buttonText = 'Connect';
    });
  }

  void _toggleWebSocketConnection() {
    ServerInfo? selectedServer =
        servers.firstWhereOrNull((server) => server.isSelected);

    if (selectedServer == null) {
      setState(() {
        _validationMessage = 'No server selected. Please select a server.';
      });
      return;
    }

    String uriString =
        'ws://${selectedServer.address}:${selectedServer.port}/ws';

    if (widget.webSocketManager.isConnected) {
      widget.webSocketManager.close();
      setState(() {
        _buttonText = 'Connect';
      });
    } else {
      widget.webSocketManager.connect(Uri.parse(uriString));
      setState(() {
        _buttonText = 'Disconnect';
      });
    }
  }

  String? _getSelectedServerUri() {
    ServerInfo? selectedServer =
        servers.firstWhereOrNull((server) => server.isSelected);
    if (selectedServer != null) {
      return 'ws://${selectedServer.address}:${selectedServer.port}/ws';
    }
    return null;
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool autoConnectValue = prefs.getBool('auto_connect') ?? false;
    bool autoReconnectValue = prefs.getBool('auto_reconnect') ?? false;

    setState(() {
      _autoConnect = autoConnectValue;
      _autoReconnect = autoReconnectValue;
    });
  }

  void _clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      // Reset the relevant state variables
      servers.clear();
      // Reset other relevant variables if needed
      // Example:
      _autoConnect = false;
      _autoReconnect = false;
    });

    // Optionally, navigate the user to a different screen or show a confirmation message
  }

  Widget _buildTableHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
              flex: 3, child: Text('IP', style: AppStyles.tableHeaderText)),
          Expanded(
              flex: 2, child: Text('Port', style: AppStyles.tableHeaderText)),
          Expanded(
              flex: 2, child: Text('Delete', style: AppStyles.tableHeaderText)),
          Expanded(
              flex: 2,
              child: Text('Selected', style: AppStyles.tableHeaderText)),
        ],
      ),
    );
  }

  Widget _buildServerList() {
    return Scrollbar(
      thumbVisibility:
          true, // Set this to true to always show the scrollbar thumb
      child: ListView.builder(
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          return Container(
            color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Expanded(
                      flex: 3,
                      child:
                          Text(server.address, style: AppStyles.tableRowText)),
                  Expanded(
                      flex: 2,
                      child: Text(server.port, style: AppStyles.tableRowText)),
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeServer(index),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Checkbox(
                      value: server.isSelected,
                      onChanged: (bool? value) {
                        _selectServer(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Server Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Server Address'),
            ),
            TextField(
              controller: _portController,
              decoration: InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            CheckboxListTile(
              title: Text("Auto Connect"),
              value: _autoConnect,
              onChanged: servers.any((server) => server.isSelected)
                  ? (bool? value) async {
                      if (value != null) {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('auto_connect', value);

                        setState(() {
                          _autoConnect = value;
                        });

                        // Update WebSocketManager setting
                        widget.webSocketManager.setAutoReconnect(value);
                      }
                    }
                  : null, // Disable if no server is selected
            ),
            CheckboxListTile(
              title: Text("Reconnect if Disconnected"),
              value: _autoReconnect,
              onChanged: (bool? value) {
                setState(() {
                  _autoReconnect = value ?? false;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Wrap(
                spacing: 20, // horizontal space between buttons
                runSpacing: 20, // vertical space between lines
                alignment: WrapAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _toggleWebSocketConnection,
                    child: Text(_buttonText),
                  ),
                  ElevatedButton(
                    onPressed: _addServer,
                    child: Text('Add Server'),
                  ),
                  ElevatedButton(
                    onPressed: _clearSharedPreferences,
                    child: Text('Clear All Settings'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(_validationMessage),
            SizedBox(height: 20),
            _buildTableHeaders(),
            Expanded(child: _buildServerList()),
          ],
        ),
      ),
    );
  }
}
