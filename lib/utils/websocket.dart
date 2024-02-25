// ignore_for_file: unnecessary_null_comparison, unused_element

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WebSocketManager {
  late WebSocketChannel _channel;
  late Uri _uri;
  String? _clientId; // Property to store the clientId

  // Lists of callback functions.
  Map<String, Function(String)> onErrorHandlers = {};
  Map<String, Function(bool)> onConnectionChangedHandlers = {};
  Map<String, Function(dynamic)> onReceiveHandlers = {};
  Map<String, Function()> onHeartBeatHandlers = {};
  Map<String, Function(dynamic)> onUserInputRequiredHandlers = {};
  Map<String, Function(String)> onConnectionFailureHandlers = {};
  Map<String, Function(dynamic)> onPartAddedHandlers = {};

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

  void stopConnection() {
    _isDisconnectionIntentional = true;
    _isConnected = false;
    _channel.sink.close();
  }

  void removeHandler(String handlerName, String setName) {
    // Map of handler sets for easy lookup
    Map<String, Map<String, Function>> handlerSets = {
      'onErrorHandlers': onErrorHandlers,
      'onConnectionChangedHandlers': onConnectionChangedHandlers,
      'onReceiveHandlers': onReceiveHandlers,
      'onHeartBeatHandlers':
          onHeartBeatHandlers.map((key, value) => MapEntry(key, () => value())),
      'onUserInputRequiredHandlers': onUserInputRequiredHandlers,
      'onConnectionFailureHandlers': onConnectionFailureHandlers,
      'onPartAddedHandlers': onPartAddedHandlers,
    };

    // Check if the setName is valid and contains the handler
    if (handlerSets.containsKey(setName) &&
        handlerSets[setName]!.containsKey(handlerName)) {
      handlerSets[setName]!.remove(handlerName);
      if (kDebugMode) {
        print("Handler removed from WebSocket manager: $handlerName");
      }
    } else {
      if (kDebugMode) {
        print("Handler set name is invalid or handler does not exist.");
      }
    }
  }

  void addHandler(String identifier, dynamic handler, String setName) {
    final Map<String, Map<String, dynamic>> sets = {
      'onErrorHandlers': onErrorHandlers,
      'onConnectionChangedHandlers': onConnectionChangedHandlers,
      'onReceiveHandlers': onReceiveHandlers,
      'onHeartBeatHandlers': onHeartBeatHandlers,
      'onUserInputRequiredHandlers': onUserInputRequiredHandlers,
      'onConnectionFailureHandlers': onConnectionFailureHandlers,
      'onPartAddedHandlers': onPartAddedHandlers,
    };

    // Check if the set name is valid and if the identifier is not already in use
    if (sets.containsKey(setName) && !sets[setName]!.containsKey(identifier)) {
      sets[setName]![identifier] = handler;
      print("Handler added to $setName for identifier: $identifier");
    } else {
      removeHandler(identifier, setName);
      addHandler(identifier, handler, setName);
      print(
          "Removed existing $setName and readded it $identifier.");
      
      
    }
  }

  // Notifies all registered handlers about the received data.
  void _notifyOnReceive(dynamic data) {
    if (data == 'heartbeat') {
      if (kDebugMode) {
        print("Heart beat detected");
      }
      _resetTimer();

      _notifyOnHeartBeat();
    } else if (data.contains("clientId")) {
      var jsonData = jsonDecode(data);
      _clientId = jsonData["clientId"];
      print("Received clientId: $_clientId");
    } else {
      // All data will be json except for heartbeat
      Map<dynamic, dynamic> jsonData = jsonDecode(data);

      if (jsonData.containsKey('required_inputs')) {
        // This is a user input required event
        _notifyOnUserInputRequired(data);
      } else if (jsonData.containsKey('event')) {
        switch (jsonData['event']) {
          case "question":
            // This is a user input question event TODO: This might need a client id?
            _notifyOnUserInputRequired(data);
            break;
          case "part_added":
            _notifyOnPartAdded(jsonData);

          default:
            // Default case to handle other events
            for (var handler in onReceiveHandlers.values) {
              handler(data);
            }
            break;
        }
      }
    }
  }

  void _notifyOnConnectionFailure(String errorMessage) {
    for (var handler in onConnectionFailureHandlers.values) {
      handler(errorMessage);
    }
  }

  // Notifies all registered handlers about the connection status change.
  void _notifyConnectionStatusChange(bool isConnected) {
    _isConnected = isConnected;
    for (var handler in onConnectionChangedHandlers.values) {
      handler(isConnected);
    }
  }

  // Notifies all registered handlers about the heartbeat data.
  void _notifyOnHeartBeat() {
    for (var handler in onHeartBeatHandlers.values) {
      handler();
    }
  }

  void _notifyOnPartAdded(dynamic data) {
    for (var handler in onPartAddedHandlers.values) {
      handler(data);
    }
  }

  // Notifies all registered handlers about the heartbeat data.
  void _notifyOnUserInputRequired(data) {
    for (var handler in onUserInputRequiredHandlers.values) {
      handler(data);
    }
  }

  // Notifies all registered handlers about the error occurred.
  void _notifyOnError(String errorMessage) {
    for (var handler in onErrorHandlers.values) {
      handler(errorMessage);
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

      // Attempt to connect
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 5),
      );

      // Handle immediate connection errors
      _channel.stream.handleError((error) {
        print('Immediate connection error: $error');
        _handleConnectionError(error);
      });

      // Separate method to start listening once connection is established
      _startListening();
    } else {
      print("Already connected...");
    }
  }

 void _startListening() {
  _channel.stream.listen((data) {
    // Data received, connection is established
    if (!_isConnected) {
      _isConnected = true;
      _notifyConnectionStatusChange(true);
    }
    print('Received data: $data'); // Log received data
    _notifyOnReceive(data);
  }, onDone: () {
    // Connection is closed
    _handleConnectionClosure();
  }, onError: (error, StackTrace stackTrace) {
    // Error occurred
    print('Error occurred: $error'); // Log error
    print('Stack trace: $stackTrace'); // Log stack trace
    _handleConnectionError(error);
  });
}

  void _handleConnectionError(error) {
    _isConnected = false;
    _notifyConnectionStatusChange(false);

    String errorMessage;
    if (error is SocketException) {
      // Handle socket exception separately
      errorMessage =
          "Cannot connect to the server at ${_uri.host}:${_uri.port}. Please check your network connection and server status.";
    } else {
      // General error message
      errorMessage = "Connection error: $error";
    }

    _notifyOnConnectionFailure(errorMessage);
    print(errorMessage);
  }



  void _handleConnectionClosure([int? closeCode, String? closeReason]) {
    print(
        'WebSocket connection closed with code $closeCode and reason $closeReason');
    _isConnected = false;
    _notifyConnectionStatusChange(false);
    if (!_isDisconnectionIntentional) {
      _notifyOnConnectionFailure("Connection closed unexpectedly");
    }
  }

  void _resetTimer() {
    print("Resetting Timer");
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 10), _handleTimeout);
  }

  void _handleTimeout() {
    if (kDebugMode) {
      print('WebSocket connection timed out');
    }
    _isConnected = false;
    _channel.sink.close();
    _notifyConnectionStatusChange(false);

    if (_autoReconnect) {
      if (kDebugMode) {
        print("Attempting to reconnect to WebSocket server");
      }
      Timer(const Duration(seconds: 5), () => connect(_uri));
    }

    _stopTimer(); // Add this to ensure the timer is stopped.
  }

  void _stopTimer() {
    if (kDebugMode) {
      print("Timer Stopped");
    }
    if (_timer != null) {
      _timer!.cancel();
      if (kDebugMode) {
        print("Timer Stopped");
      }
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
    if (_clientId != null) {
      Map<String, dynamic> messageData;

      // Check if the message is already a JSON string.
      if (!message.contains('clientId')) {
        print("Adding clientId $_clientId to the message");

        // Try to decode the message to see if it's a valid JSON.
        try {
          messageData = jsonDecode(message);
        } catch (e) {
          // If it's not JSON, treat it as a plain string message.
          messageData = {"data": message};
        }

        // Append the clientId to the message data.
        messageData["clientId"] = _clientId;

        // Encode the combined data back to JSON string.
        String messageWithClientId = jsonEncode(messageData);
        _channel.sink.add(messageWithClientId);
      } else {
        // If clientId is already present, send the message as it is.
        _channel.sink.add(message);
      }
    } else {
      print("ClientId is not set. Cannot send message.");
    }
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
