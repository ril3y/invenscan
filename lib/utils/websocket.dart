// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketManager {
  late WebSocketChannel _channel;
  late Uri _uri;
  late Function onReceive;
  late Function onDisconnect;

  Timer? _timer;
  bool _autoReconnect = false;
  bool _autoConnect = false;
  bool _isConnected = false;

  WebSocketManager(this.onReceive, this.onDisconnect){
    _loadSettingsAndConnect();
  }

  bool get isConnected => _isConnected;

  Function(String)? onError;
  Function(bool)? onConnectionChanged;

  Future<void> _loadSettingsAndConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');
    _autoConnect = prefs.getBool('auto_connect') ?? false;
    _autoReconnect = prefs.getBool('auto_reconnect') ?? false;

    if (serverAddress != null && serverPort != null && _autoConnect) {
      _uri = Uri.parse('ws://$serverAddress:$serverPort/ws');
      connect(_uri);
    }
  }

  void connect(Uri uri) {
    _uri = uri;
    _channel = IOWebSocketChannel.connect(
      uri,
      pingInterval: const Duration(seconds: 5),
    );
    _startListening();

    // _channel.stream.listen(
    //   (data) {
    //     if (!_isConnected) {
    //       _updateConnectionStatus(true);
    //     }
    //     onReceive(data);
    //     print(data);
    //   },
    //   onError: (error) {
    //     _handleError(error);
    //   },
    //   onDone: _handleDone,
    // );
  }

//   void _handleDone() {
//     print('WebSocket connection closed by the server');
//     _updateConnectionStatus(false);
//     if (_autoReconnect) {
//       _attemptReconnect();
//     }
//   }

//   void _handleError(dynamic error) {
//   print('WebSocket error: $error');
//   _updateConnectionStatus(false);
//   onError?.call("Failed to connect: $error");
//   if (_autoReconnect) {
//     _attemptReconnect();
//   }
// }

  void _startListening() {
    var timeoutDuration = const Duration(seconds: 15);
    _timer = Timer(timeoutDuration, _handleTimeout);

    _channel.stream.listen((data) {
      // _updateConnectionStatus(true);

      if (data == 'heartbeat') {
        print('Heartbeat received, resetting timer.');
        _resetTimer();
      }

      onReceive(data);
    }, onError: (error) {
      _updateConnectionStatus(false);
      _attemptReconnect(); // New method to handle reconnection
    }, onDone: () {
      _updateConnectionStatus(false);
      _attemptReconnect(); // New method to handle reconnection
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), _handleTimeout);
  }

  void _handleTimeout() {
    print('WebSocket connection timed out');

    _channel.sink.close();
    if (_autoReconnect && _uri != null) {
      Timer(const Duration(seconds: 5), () => connect(_uri));
    } else {
      _updateConnectionStatus(false);
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
    onConnectionChanged?.call(_isConnected);
  }

  void send(String message) {
    _channel.sink.add(message);
  }

  void _attemptReconnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool currentAutoReconnect = prefs.getBool('auto_reconnect') ?? false;

    if (currentAutoReconnect && _uri != null) {
      Timer(const Duration(seconds: 5), () => connect(_uri));
    }
  }

  void setAutoReconnect(bool value) {
    _autoReconnect = value;
  }

  void setReconnect(bool value) {
    _autoConnect = value; // This seems like it should be _autoReconnect
  }

  void close() {
    _isConnected = false;
    _channel.sink.close();
  }
}
