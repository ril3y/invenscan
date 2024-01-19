// scanner_service.dart

import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart' as barcode_scan2;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScannerService {
CameraController? _camera;
  CameraController? _camera;
  final textDetector = GoogleMlKit.vision.textRecognizer();
  ScannerService();

  
  
Future<List<int>> scan() async {
  var result = await barcode_scan2.BarcodeScanner.scan();
  // Check for a valid result
  if (result.type == barcode_scan2.ResultType.Barcode) {
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

  Stream<CameraImage> cameraImageStream() {
    return _camera!.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation imageRotation = InputImageRotationMethods.fromRawValue(_camera!.description.sensorOrientation) ?? InputImageRotation.Rotation_0deg;
    final InputImageFormat inputImageFormat = InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.NV21;
    final planeData = image.planes.map((Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    }).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );
    final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    final RecognizedText recognizedText = await textDetector.processImage(inputImage);
    // TODO: Implement the logic to handle clickable text blocks based on recognizedText
  }

  Future<List<String>> getTextBlocks() async {
    // TODO: Implement the logic to return text blocks as a list of strings
    return [];
  }

}
