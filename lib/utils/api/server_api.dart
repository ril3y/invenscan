import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'location.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ServerApi {
  static Future<String> _getServerUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

    if (serverAddress != null && serverPort != null) {
      return 'http://$serverAddress:$serverPort';
    } else {
      throw Exception('Server address and port not set');
    }
  }

  static Future<Map<String, dynamic>> addPart(
      Map<String, dynamic> partData) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/add_part');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(partData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to add part. Status code: ${response.statusCode}');
    }
  }

    static Future<Map<String, dynamic>> addLocation(
      Map<String, dynamic> partData) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/add_location/');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(partData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to add location. Status code: ${response.statusCode}');
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    String baseUrl = await _getServerUrl();

    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_image'));
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      // Handle successful upload
    } else {
      // Handle error
    }
  }

static Future<Map<String, dynamic>> getCounts() async {
  String baseUrl = await _getServerUrl();
  var url = Uri.parse('$baseUrl/get_counts');
  var response = await http.get(url);
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data; // Now correctly returning a Map<String, dynamic>
  } else {
    throw Exception('Failed to load counts');
  }
}


  static Future<List<Location>> fetchLocations() async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse(
        '$baseUrl/get_all_locations'); // Adjust the endpoint as necessary
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var responseBody =
          jsonDecode(response.body); // Decode JSON from the response body
      List<Location> allLocations = (responseBody['locations'] as List)
          .map((locationJson) => Location.fromJson(locationJson))
          .toList();

      // Filter locations where 'parent_id' is null
      List<Location> locationsWithoutParent =
          allLocations.where((location) => location.parentId == null).toList();

      return locationsWithoutParent;
    } else {
      throw Exception('Failed to load locations');
    }
  }
}
