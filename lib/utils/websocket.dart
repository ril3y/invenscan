// ignore_for_file: unnecessary_null_comparison, unused_element

import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WebSocketManager {
  late WebSocketChannel _channel;
  late Uri _uri;
  String? _clientId; // Property to store the clientId

  // Lists of callback functions.
  List<Function(String)> onError = [];
  List<Function(bool)> onConnectionChanged = [];
  List<Function(dynamic)> onReceive = [];
  List<Function()> onHeartBeat = [];
  List<Function(dynamic)> onPartAdded = [];
  List<Function(dynamic)> onUserInputRequired = [];
  List<Function(String)> onConnectionFailure = [];

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

  // Adds a handler for receiving data from the WebSocket.
  void addOnPartAddedHandler(Function(dynamic) handler) {
    onPartAdded.add(handler);
  }

  // Adds a handler for receiving user input required from the WebSocket.
  void addOnUserInputRequired(Function(dynamic) handler) {
    onUserInputRequired.add(handler);
  }

  // Adds a handler for receiving heartbeat data from the WebSocket.
  void addOnHeartbeatHandler(Function() handler) {
    onHeartBeat.add(handler);
  }

  // Adds a handler to be called when the connection status changes.
  void addOnConnectionChangedHandler(Function(bool) handler) {
    onConnectionChanged.add(handler);
  }



  // Adds a handler to be called on WebSocket error.
  void addOnError(Function(String) handler) {
    onError.add(handler);
  }

  void addOnConnectionFailureHandler(Function(String) handler) {
    onConnectionFailure.add(handler);
  }

  void _notifyOnConnectionFailure(String errorMessage) {
    for (var handler in onConnectionFailure) {
      handler(errorMessage);
    }
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
    if (data == 'heartbeat') {
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
            for (var handler in onReceive) {
              handler(data);
            }
            break;
        }
      }
    }
  }

  // Notifies all registered handlers about the heartbeat data.
  void _notifyOnHeartBeat() {
    for (var handler in onHeartBeat) {
      handler();
    }
  }

  void _notifyOnPartAdded(data) {
    for (var handler in onPartAdded) {
      handler(data);
    }
  }

  // Notifies all registered handlers about the heartbeat data.
  void _notifyOnUserInputRequired(data) {
    for (var handler in onUserInputRequired) {
      handler(data);
    }
  }

  // Notifies all registered handlers about the error occurred.
  void _notifyOnError(String errorMessage) {
    for (var handler in onError) {
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
    _notifyOnReceive(data);
  }, onDone: () {
    // Connection is closed
    _handleConnectionClosure();
  }, onError: (error) {
    // Error occurred
    _handleConnectionError(error);
  });
}

void _handleConnectionError(error) {
  _isConnected = false;
  _notifyConnectionStatusChange(false);

  String errorMessage;
  if (error is SocketException) {
    // Handle socket exception separately
    errorMessage = "Cannot connect to the server at ${_uri.host}:${_uri.port}. Please check your network connection and server status.";
  } else {
    // General error message
    errorMessage = "Connection error: $error";
  }

  _notifyOnConnectionFailure(errorMessage);
  print(errorMessage);
}


void _handleConnectionClosure() {
  print('WebSocket connection closed');
  _isConnected = false;
  _notifyConnectionStatusChange(false);
  if (!_isDisconnectionIntentional) {
    _notifyOnConnectionFailure("Connection closed unexpectedly");
  }
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