// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names

import '../utils/websocket.dart';
import 'package:flutter/material.dart';
import '../ui/balloon.dart';

class HeartbeatIcon extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const HeartbeatIcon({Key? key, required this.webSocketManager}) : super(key: key);

  @override
  _HeartbeatIconState createState() => _HeartbeatIconState();
}

class _HeartbeatIconState extends State<HeartbeatIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isConnected = false;

  void _onConnectionChangeHandler(bool isConnected) {
    setState(() {
      _isConnected = isConnected;
    });
  }

  void _onDataHandler(data){
      if (data == 'heartbeat' && mounted) {
        _animationController.forward(from: 0.0);
      }
    }

  @override
  void initState() {
    super.initState();

    // Set our callbacks to the websocket methods.
    widget.webSocketManager.addOnConnectionChangedHandler(_onConnectionChangeHandler);
    widget.webSocketManager.addOnReceiveHandler(_onDataHandler);
    
    _animationController = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Total duration for the pulse
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 25),
    ]).animate(_animationController);

    _colorAnimation = ColorTween(
      begin: Colors.redAccent, // Normal color
      end: Colors.red, // Color when beating
    ).animate(_animationController);

    
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      if (_isConnected) {
        return Padding(
          padding: EdgeInsets.only(right: 8.0),  // Adjust the padding value as needed
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: InkWell(
              onTap: () {
                // Define your action here
                print('Heart icon tapped');
              },
              child: Icon(
                Icons.favorite,
                color: _colorAnimation.value ?? Colors.blue, // Use animated color
                size: 24, // Update size as needed
              ),
            ),
          ),
        );
      } else {
        // Return an empty container when not connected
        return Container();
      }
    },
  );
}

}
