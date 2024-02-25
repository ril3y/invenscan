// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names

import '../utils/websocket.dart';
import 'package:flutter/material.dart';

class HeartbeatIcon extends StatefulWidget {
  final WebSocketManager webSocketManager;

  const HeartbeatIcon({super.key, required this.webSocketManager});

  @override
  _HeartbeatIconState createState() => _HeartbeatIconState();
}

<<<<<<< HEAD
class _HeartbeatIconState extends State<HeartbeatIcon>
    with SingleTickerProviderStateMixin {
=======
class _HeartbeatIconState extends State<HeartbeatIcon> with SingleTickerProviderStateMixin {
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isConnected = false;

  void _onConnectionChangeHandler(bool isConnected) {
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _onHeartBeatHandler() {
    if (mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void initState() {
    super.initState();

<<<<<<< HEAD
    widget.webSocketManager
        .addHandler("heartbeat", _onConnectionChangeHandler, "onConnectionChangeHandlers");
    widget.webSocketManager
        .addHandler("heartbeat", _onHeartBeatHandler, "onHeartBeatHandlers");

    _animationController = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Total duration for the pulse
=======
    widget.webSocketManager.addOnConnectionChangedHandler(_onConnectionChangeHandler);
    widget.webSocketManager.addOnHeartbeatHandler(_onHeartBeatHandler);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Total duration for the pulse
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
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
        return _isConnected
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: () {
                      print('Heart icon tapped');
                    },
                    child: Icon(
                      Icons.favorite,
                      color: _colorAnimation.value ?? Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              )
            : Container();
      },
    );
  }
}
