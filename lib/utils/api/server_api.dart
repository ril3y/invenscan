import 'package:invenscan/utils/api/category.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'location.dart';

class ServerApi {
  static Future<String> _getServerUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serverAddress = prefs.getString('selected_server_address');
    String? serverPort = prefs.getString('selected_server_port');

    return 'http://$serverAddress:$serverPort';
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
        http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_image/'));
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

  static Future<Map<String, dynamic>> performSearch(
      String query, String searchType) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse(
        '$baseUrl/search/$query?search_type=$searchType'); // Assuming your API has a searchType parameter
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return {
        'searchResults': (data['search_results'] as List<dynamic>)
            .map((result) => result as Map<String, dynamic>)
            .toList(),
        'suggestions': data['suggestions']
      };
    } else {
      throw Exception(
          'Failed to perform search. Status code: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getLocationPath(String locationId) async {
    try {
      String baseUrl = await _getServerUrl();
      var url = Uri.parse('$baseUrl/get_location_path/$locationId');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        // Parsing the response assuming it's a Map
        var data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        // Handle different response status codes as needed
        print('Server responded with status code: ${response.statusCode}');
        throw Exception(
            'Failed to load location path. Status code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Handle client-side errors
      print('ClientException occurred: $e');
      throw Exception('Failed to load location path due to client error: $e');
    } catch (e) {
      // Handle any other types of exceptions
      print('An unexpected error occurred: $e');
      throw Exception(
          'Failed to load location path due to unexpected error: $e');
    }
  }

  static Future<List<Location>> getLocationDetails(String locationId) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/get_location_details/$locationId');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((locationData) => Location.fromJson(locationData))
          .toList();
    } else {
      throw Exception(
          'Failed to load location details. Status code: ${response.statusCode}');
    }
  }

  static Future<List<PartModel>> getParts(int page, int pageSize) async {
    String baseUrl =
        await _getServerUrl(); // Assuming _getServerUrl() is implemented elsewhere
    var url = Uri.parse('$baseUrl/all_parts/?page=$page&page_size=$pageSize');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response
          .body); // Assuming the response is a map containing a 'parts' list
      return data.map((partData) => PartModel.fromJson(partData)).toList();
    } else {
      throw Exception(
          'Failed to load parts. Status code: ${response.statusCode}');
    }
  }

  static Future<http.Response> deleteLocation(String locationId) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/delete_location/$locationId');
    var response = await http.delete(url);

    if (response.statusCode != 200) {
      // You can handle different status codes differently if needed
      throw Exception(
          'Failed to delete location. Status code: ${response.statusCode}');
    }
    return response;

    // If the deletion is successful, no return is needed. You can also handle
    // any response data here if your API provides it.
  }

  static Future<http.Response> deletePart(String partId) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/delete_part/$partId');
    var response = await http.delete(url);

    if (response.statusCode != 200) {
      // You can handle different status codes differently if needed
      throw Exception(
          'Failed to delete part. Status code: ${response.statusCode}');
    }
    return response;

    // If the deletion is successful, no return is needed. You can also handle
    // any response data here if your API provides it.
  }

  static Future<Map<String, dynamic>> previewDeleteLocation(
      String locationId) async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/preview-delete/$locationId');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to preview delete location. Status code: ${response.statusCode}');
    }
  }

  static Future<List<Location>> fetchLocations() async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/get_all_locations/');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      List<Location> allLocations = (responseBody['locations'] as List)
          .map((locationJson) => Location.fromJson(locationJson))
          .toList();

      // // Filter locations where 'parent_id' is null
      // List<Location> locationsWithoutParent =
      //     allLocations.where((location) => location.parentId == null).toList();

      return allLocations;
    } else {
      throw Exception('Failed to load locations');
    }
  }

  static Future<List<Category>> fetchCategories() async {
    String baseUrl = await _getServerUrl();
    var url = Uri.parse(
        '$baseUrl/all_categories/'); // Adjust the endpoint as necessary
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      List<Category> allCategories = (responseBody['categories']
              as List) // Ensure the key matches your JSON structure
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();

      return allCategories;
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<Map<String, dynamic>> updatePart(PartModel partData) async {
    var jsonPart = partData.toJson();
    var partId = jsonPart['part_id'];
    String baseUrl = await _getServerUrl();
    var url = Uri.parse('$baseUrl/update_part/$partId');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(jsonPart),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to add part. Status code: ${response.statusCode}');
    }
  }
}
