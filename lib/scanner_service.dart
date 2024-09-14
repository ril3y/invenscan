import 'package:camera/camera.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

class ScannerService {
  CameraController? _camera;

  Future<List<int>> scanBarcode() async {
    var result = await BarcodeScanner.scan();
    // Check for a valid result
    if (result.type == ResultType.Barcode) {
      var bytes = utf8.encode(result.rawContent);
      // Return the byte array directly
      return bytes;
    } else {
      // Handle the case where scanning did not return a valid barcode
      // This could be an error or a cancelled scan.
      throw Exception('No valid barcode');
    }
  }


  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _camera = CameraController(firstCamera, ResolutionPreset.medium);
    await _camera?.initialize();
  }

void cameraImageStream(Function(CameraImage) processImage) {
  if (_camera == null) {
    throw StateError('CameraController is not initialized');
  }
  _camera!.startImageStream((CameraImage availableImage) {
    processImage(availableImage);
  });
}

  Future<void> _processImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
  }
}