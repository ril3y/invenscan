// scanner_service.dart

import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart'; // or your specific barcode scan package

class ScannerService {

  ScannerService();
  
Future<List<int>> scan() async {
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


  // Future<String> _scan() async {
  //   var result = await BarcodeScanner.scan();
  //     var bytes = utf8.encode(result.rawContent);
  //     var hexString =
  //         bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  //     print("Scanned: " + hexString);
  //     print("ASCII:" + result.rawContent);

  //     List<List<int>> records = [];
  //     List<int> currentRecord = [];
  //     List<int> currentField = [];

  //     for (var byte in bytes) {
  //       if (byte == 29) {
  //         currentRecord
  //             .add(30); // Add RS to represent GS when converting to string.
  //         currentRecord.addAll(currentField);
  //         currentField = [];
  //       } else if (byte == 30) {
  //         records.add(currentRecord);
  //         currentRecord = [];
  //       } else {
  //         currentField.add(byte);
  //       }
  //     }

  //     if (currentField.isNotEmpty) {
  //       currentRecord.addAll(currentField);
  //     }

  //     if (currentRecord.isNotEmpty) {
  //       records.add(currentRecord);
  //     }

  //     for (var record in records) {
  //       print(String.fromCharCodes(record).replaceAll('\x1e', '|'));
  //     }
  
  //     return result.rawContent.toString();
  // }
}
