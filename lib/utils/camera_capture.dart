import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeCameraControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

Future<void> _initializeCamera() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(firstCamera, ResolutionPreset.low);
    await _cameraController!.initialize();

    setState(() {
      // This will trigger a rebuild of the widget with the initialized camera.
    });
  } catch (e) {
    print('Error initializing camera: $e');
  }
}


  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

Future<void> _takePicture() async {
  if (!_cameraController!.value.isInitialized) {
    // Handle the case where the camera is not initialized
    print('Error: Camera not initialized');
    return;
  }
  if (_cameraController!.value.isTakingPicture) {
    // If a picture is already being captured, do nothing
    return;
  }

  try {
    final image = await _cameraController!.takePicture();
    Navigator.pop(context, File(image.path)); // Return the image file
  } catch (e) {
    // Handle any errors here
    print('Error taking picture: $e');
    Navigator.pop(context); // Return without any file in case of error
  }
}

  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Take a Picture')),
    body: FutureBuilder<void>(
      future: _initializeCameraControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return _cameraController == null
          ? const Text('Camera not available')
          : CameraPreview(_cameraController!);
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _takePicture,
      child: const Icon(Icons.camera),
    ),
  );
}

}