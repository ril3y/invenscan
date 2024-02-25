// ignore_for_file: prefer_const_constructors
<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../utils/websocket.dart';
import 'package:shared_preferences/shared_preferences.dart';
=======

import 'package:flutter/material.dart';
import '../utils/websocket.dart'; // Replace with the actual path to your WebSocketManager
import 'package:shared_preferences/shared_preferences.dart';
bool isConnectedGlobal = false;
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133

class StatusBar extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const StatusBar({super.key, required this.webSocketManager});

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  String _connectionStatus = 'Disconnected';
  String _serverDetails = '';

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    widget.webSocketManager.addHandler(
        "status_bar", _onConnectionChanged, "onConnectionChangedHandlers");
    widget.webSocketManager.addHandler(
        "status_bar", _onConnectionFailure, "onConnectionFailureHandlers");
  }

  @override
  void dispose() {
    // widget.webSocketManager
    //     .removeHandler("status_bar", "onConnectionChangedHandlers");
    // widget.webSocketManager
    //     .removeHandler("status_bar", "onConnectionFailureHandlers");
    super.dispose();
=======
    widget.webSocketManager.addOnConnectionChangedHandler(_onConnectionChanged);
        widget.webSocketManager.addOnConnectionFailureHandler(_onConnectionFailure);

    _connectionStatus = isConnectedGlobal ? 'Connected' : 'Disconnected';
    if (isConnectedGlobal) {
      _loadServerDetails();
    }
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  }

  Future<void> _loadServerDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

<<<<<<< HEAD
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _serverDetails = '$serverAddress:$serverPort';
      });
    }
    }

  void _onConnectionFailure(error) {
    print("Error:$error");
  }

  /// Updates the connection status displayed in the status bar.
  ///
  /// If a connection is established, retrieves the server details from
  /// SharedPreferences and displays them. If disconnected, clears the
  /// server details. Updates the _connectionStatus state variable with
  /// the latest status.
  void _onConnectionChanged(bool isConnected) {
    if (!mounted) return;
    setState(() {
      if (isConnected) {
        _loadServerDetails();
        _connectionStatus = 'Connected';
      } else {
        _serverDetails = '';
        _connectionStatus = 'Disconnected';
      }
    });
=======
    if (serverAddress != null && serverPort != null) {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _serverDetails = '$serverAddress:$serverPort';
        });
      }
    }
  }

  void _onConnectionFailure(error){
    print("Error:$error");
  }

  void _onConnectionChanged(bool isConnected) {
    isConnectedGlobal = isConnected;

    if (isConnected) {
      if (mounted) {
        _loadServerDetails();
        _connectionStatus = 'Connected';
      }
    } else {
      if (mounted) {
        setState(() {
          _serverDetails = '';
          _connectionStatus = 'Disconnected';
        });
      }
    }
    _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      color: Color.fromARGB(255, 100, 94, 94),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (_connectionStatus == 'Connected' &&
              _serverDetails.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                style: TextStyle(
<<<<<<< HEAD
                  fontSize: 16,
                  color: Color.fromARGB(255, 163, 147, 3),
=======
                  fontSize: 16, // Adjust the font size as needed
                  color: Color.fromARGB(
                      255, 163, 147, 3), // Same color as the status text
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
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
<<<<<<< HEAD
          Spacer(),
          Text(
            'Status: $_connectionStatus',
            style: TextStyle(
              color: Color.fromARGB(255, 163, 147, 3),
=======
          Spacer(), // This will push the status text to the right
          Text(
            'Status: $_connectionStatus',
            style: TextStyle(
              color: Color.fromARGB(255, 163, 147, 3), // Status text color
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
            ),
          ),
        ],
      ),
    );
  }
}
