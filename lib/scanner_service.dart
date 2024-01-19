// scanner_service.dart

import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart' as barcode_scan2;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';

class ScannerService {
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

// void _processImage(CameraImage image) async {
//   final inputImage = // Convert CameraImage to InputImage
//   final RecognizedText recognizedText = await textDetector.processImage(inputImage);
//   // Extract and handle text data
// }
}
