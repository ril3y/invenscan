// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../utils/websocket.dart'; // Replace with the actual path to your WebSocketManager
import 'package:shared_preferences/shared_preferences.dart';

class StatusBar extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const StatusBar({Key? key, required this.webSocketManager}) : super(key: key);

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  String _connectionStatus = 'Disconnected';
  String _serverDetails = '';

  @override
  void initState() {
    super.initState();
    widget.webSocketManager.addOnConnectionChangedHandler(_onConnectionChanged);
    _loadServerDetails();
  }

  Future<void> _loadServerDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

    if (serverAddress != null && serverPort != null) {
      setState(() {
        _serverDetails = '$serverAddress:$serverPort';
      });
    }
  }

  void _onConnectionChanged(bool isConnected) {
    if (isConnected) {
      _loadServerDetails();
    } else {
      if (mounted) {
        setState(() {
          _serverDetails = '';
        });
      }
    }

    if (mounted) {
      setState(() {
        _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(10),
    color: Color.fromARGB(255, 100, 94, 94),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (_connectionStatus == 'Connected' && _serverDetails.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16, // Adjust the font size as needed
                color: Color.fromARGB(255, 163, 147, 3), // Same color as the status text
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'Server: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: _serverDetails,
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
        Spacer(), // This will push the status text to the right
        Text(
          'Status: $_connectionStatus',
          style: TextStyle(
            color: Color.fromARGB(255, 163, 147, 3), // Status text color
          ),
        ),
      ],
    ),
  );
}
}