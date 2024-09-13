// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../utils/websocket.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    widget.webSocketManager.addHandler(
        "status_bar", _onConnectionChanged, "onConnectionChangedHandlers");
    widget.webSocketManager.addHandler(
        "status_bar", _onConnectionFailure, "onConnectionFailureHandlers");

    // Check if the connection is already established
    if (widget.webSocketManager.checkConnectionStatus()) {
      _connectionStatus = 'Connected';
      _loadServerDetails();
    } else {
      _connectionStatus = 'Disconnected';
    }
  }

  @override
  void dispose() {
    // widget.webSocketManager
    //     .removeHandler("status_bar", "onConnectionChangedHandlers");
    // widget.webSocketManager
    //     .removeHandler("status_bar", "onConnectionFailureHandlers");
    super.dispose();
  }

  Future<void> _loadServerDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _serverDetails = '$serverAddress:$serverPort';
      });
    }
  }

  void _onConnectionFailure(error) {
    print("Error:$error");
    if (mounted) {
      setState() {
        _serverDetails = '';
      }
    } else {
      // Not mounted, so we can't update the UI. Instead, we'll just store the latest status.
      _loadServerDetails();
      _connectionStatus = 'Disconnected';
    }
  }

  /// Updates the connection status displayed in the status bar.
  ///
  /// If a connection is established, retrieves the server details from
  /// SharedPreferences and displays them. If disconnected, clears the
  /// server details. Updates the _connectionStatus state variable with
  /// the latest status.
  void _onConnectionChanged(bool isConnected) {
    _connectionStatus = isConnected ? 'Connected' : 'Disconnected';

    if (mounted) {
      setState(() {
        if (isConnected) {
          _loadServerDetails();
        } else {
          _serverDetails = '';
        }
      });
    } else {
      // Not mounted, so we can't update the UI. Instead, we'll just store the latest status.
      _loadServerDetails();
      _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
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
          if (_connectionStatus == 'Connected' &&
              _serverDetails.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 163, 147, 3),
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
          Spacer(),
          Text(
            'Status: $_connectionStatus',
            style: TextStyle(
              color: Color.fromARGB(255, 163, 147, 3),
            ),
          ),
        ],
      ),
    );
  }
}
