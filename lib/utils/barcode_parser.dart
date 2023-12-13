import 'dart:convert';
import 'user_input_requirement.dart';
import 'package:http/http.dart' as http;


abstract class BarcodeParser  {
  // Protected fields
  String? _partNumber;
  String? _partURL;
  int? _quantity;
  String? _value;
  String? _partName;
  String? _partVendor;
  String? _partType;
  String? _imageURL;
  String? _description;
  List<String> _categories = [];

  // A map to hold dynamic properties
  Map<String, dynamic> additionalProperties = {};


void addProperty(String key, dynamic value) {
  // Sanitize the key to make it a valid JSON key name
  String sanitizedKey = _sanitizeKey(key);

  // Add the sanitized key and value to additionalProperties
  additionalProperties[sanitizedKey] = value;
}

String _sanitizeKey(String key) {
  // Remove invalid characters and spaces, and replace them with underscores
  return key.replaceAll(RegExp(r'[^\w]'), '_');
}

  Future<dynamic> enrich();
  dynamic parse(List<int> byteData);
  List<UserInputRequirement> get requiredUserInputs;

  // Public getters
  String get partNumber => _partNumber ?? "";
  String get partURL => _partURL ?? "";
  int get quantity => _quantity ?? 0;
  String get value => _value ?? "";
  String get partName => _partName ?? "";
  String get partVendor => _partVendor ?? "";
  String get partType => _partType ?? "";
  String get imageURL => _imageURL ?? "";
  String get description => _description ?? "";
  List<String> get categories => _categories ?? [];

  // Public setters
  set partNumber(String value) => _partNumber = value;
  set partURL(String value) => _partURL = value;
  set quantity(int value) => _quantity = value;
  set value(String value) => _value = value;
  set partName(String value) => _partName = value;
  set partVendor(String value) => _partVendor = value;
  set partType(String value) => _partType = value;
  set imageURL(String value) => _imageURL = value;
  set categories(List<String> value) => _categories = value;
  set description(String value) => _description = value;

  bool matches(List<int> data);
  


Map<String, dynamic> toMap() {
  Map<String, dynamic> formattedData = {
    'partNumber': partNumber,
    'partType': partType,
    'categories': categories,
  };

  // Format additional properties
  Map<String, dynamic> formattedAdditionalProperties = {};
  additionalProperties.forEach((key, value) {
    formattedAdditionalProperties[key] = value; // Directly assign the value without adding extra quotes
  });

  formattedData['additionalProperties'] = formattedAdditionalProperties;

  return formattedData;
}



  void addCategory(String category) {
    _categories.add(category);
  }

static String decodeHex(String hexString) {
  try {
    var output = StringBuffer();
    if (hexString.length % 2 != 0) {
      throw const FormatException("Hex string must have an even number of characters.");
    }
    for (var i = 0; i < hexString.length; i += 2) {
      var hexChar = hexString.substring(i, i + 2);
      var byte = int.parse(hexChar, radix: 16);
      output.writeCharCode(byte);
    }
    return output.toString();
  } catch (e) {
    // Handle parsing error
    print("Error decoding hex string: $e");
    return ""; // Return an empty string or handle it as per your application's requirement
  }
}

  // Method to convert data to a byte array (if needed)
  static List<int> toBytes(String data) {
    return utf8.encode(data);
  }
}