// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketManager {
  late WebSocketChannel _channel;
  late Uri _uri;

  // Lists of callback functions.
  List<Function(String)> onError = [];
  List<Function(bool)> onConnectionChanged = [];
  List<Function(dynamic)> onReceive = [];
  List<Function()> onDisconnect = [];
  bool _isDisconnectionIntentional = false;

  Timer? _timer;
  bool _autoReconnect = false;
  bool _autoConnect = false;
  bool _isConnected = false;

  WebSocketManager();

  bool get isConnected => _isConnected;

  // Initialize connection settings and attempt to connect if autoConnect is enabled.
  void startConnection() async {
    await loadSettingsAndConnect();
  }

  // Methods to add callbacks to their respective lists.

  // Adds a handler for receiving data from the WebSocket.
  void addOnReceiveHandler(Function(dynamic) handler) {
    onReceive.add(handler);
  }

  // Adds a handler to be called when the connection status changes.
  void addOnConnectionChangedHandler(Function(bool) handler) {
    onConnectionChanged.add(handler);
  }

  // Adds a handler to be called when the WebSocket connection is closed.
  void addOnDisconnectHandler(Function() handler) {
    onDisconnect.add(handler);
  }

  // Adds a handler to be called on WebSocket error.
  void addOnError(Function(String) handler) {
    onError.add(handler);
  }

  // Notifies all registered handlers about the connection status change.
  void _notifyConnectionStatusChange(bool isConnected) {
    _isConnected = isConnected;
    for (var handler in onConnectionChanged) {
      handler(isConnected);
    }
  }

  // Notifies all registered handlers about the received data.
  void _notifyOnReceive(dynamic data) {
    for (var handler in onReceive) {
      handler(data);
    }
  }

  // Notifies all registered handlers about the error occurred.
  void _notifyOnError(String errorMessage) {
    for (var handler in onError) {
      handler(errorMessage);
    }
  }

  // Notifies all registered handlers when the WebSocket connection is closed.
  void _notifyOnDisconnect() {
    for (var handler in onDisconnect) {
      handler();
    }
  }

  Future<void> loadSettingsAndConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');
    _autoConnect = prefs.getBool('auto_connect') ?? false;
    _autoReconnect = prefs.getBool('auto_reconnect') ?? false;

    //attemp to connect, autoconnect or reconnect if enabled
    if (serverAddress != null && serverPort != null && _autoConnect ||
        _autoReconnect) {
      _uri = Uri.parse('ws://$serverAddress:$serverPort/ws');
      connect(_uri);
    }
  }

  void connect(Uri uri) {
    if (!_isConnected) {
      _isDisconnectionIntentional = false;
      _uri = uri;
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 5),
      );
      _startListening();
    } else {
      print("Already connected... ");
    }
  }

  void _startListening() {
    var timeoutDuration = const Duration(seconds: 15);
    _timer = Timer(timeoutDuration, _handleTimeout);
    _updateConnectionStatus(true);

    _channel.stream.listen((data) {
      if (data == 'heartbeat') {
        print('Heartbeat received, resetting timer.');
        _resetTimer();
      }

      // Using null-aware call operator to safely invoke onReceive if it's not null
      _notifyOnReceive(data);
    }, onError: (error) {
      _notifyOnError(error);
      _updateConnectionStatus(false);
      _stopTimer(); // Stop the timer on error

      // Handle the SocketException here
      if (error is SocketException) {
        print(
            'SocketException: Connection refused. Attempting to reconnect...');
        _attemptReconnect();
      } else {
        print('WebSocket error: $error');
        // Handle other types of errors here
      }
    }, onDone: () {
      if (!_isDisconnectionIntentional) {
        print('WebSocket disconnected unexpectedly');
        _updateConnectionStatus(false);
        _attemptReconnect();
      } else {
        print('WebSocket disconnected intentionally');
        _updateConnectionStatus(false);
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 45), _handleTimeout);
  }

  void _handleTimeout() {
    print('WebSocket connection timed out');
    _isConnected = false;
    _channel.sink.close();
    _notifyConnectionStatusChange(false);

    if (_autoReconnect) {
      print("Attempting to reconnect to WebSocket server");
      Timer(const Duration(seconds: 5), () => connect(_uri));
    }

    _stopTimer(); // Add this to ensure the timer is stopped.
  }

  void _stopTimer() {
    print("Timer Stopped");
    if (_timer != null) {
      _timer!.cancel();
      print("Timer Stopped");
      _timer = null;
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
    _notifyConnectionStatusChange(isConnected);

    if (!isConnected) {
      _stopTimer(); // Stop the timer if disconnected
    }
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
    _isDisconnectionIntentional = true;
    _channel.sink.close();
  }
}
