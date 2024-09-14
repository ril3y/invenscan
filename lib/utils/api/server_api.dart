import 'package:invenscan/part_data.dart';
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

  static Future<http.Response> printQrCode(
      {String? partNumber, String? partName}) async {
    String baseUrl = await _getServerUrl();

    // Ensure that at least one of partName or partNumber is provided
    if (partName == null && partNumber == null) {
      throw Exception(
          "At least one of partName or partNumber must be provided.");
    }

    // Build the URL for the API endpoint
    var url = Uri.parse('$baseUrl/printer/print_qr');

    // Create the request payload
    var requestBody = jsonEncode({
      "part_number": partNumber,
      "part_name": partName,
    });

    // Send the POST request to print the QR code
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: requestBody,
    );

    // Return the response object to handle in the calling method
    return response;
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

  static Future<Location?> getLocationById(String locationId) async {
    String baseUrl =
        await _getServerUrl(); // Assuming you have this method to get your server URL

    // Build the URL for the API endpoint
    var url = Uri.parse('$baseUrl/get_location/$locationId');

    // Send the GET request to fetch the location data
    var response = await http.get(url);

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Parse the JSON response
      var jsonData = jsonDecode(response.body);

      // Assuming Location has a fromJson method
      return Location.fromJson(jsonData);
    } else {
      // Handle the error response, return null or throw an exception
      print('Failed to load location: ${response.statusCode}');
      return null;
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

  static Future<http.Response> deletePart(String? partId) async {
    String baseUrl =
        await _getServerUrl(); // Assume this method gets the base URL
    var url = Uri.parse('$baseUrl/delete_part/$partId'); // Form the delete URL

    var response = await http.delete(url); // Make the DELETE request

    if (response.statusCode != 200) {
      // Handle non-200 responses, you could also handle different status codes here
      throw Exception(
          'Failed to delete part. Status code: ${response.statusCode}');
    }

    return response; // Return the response if needed for further processing
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

  static Future<String> updatePart(PartModel partData) async {
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
      return response.body;
    } else {
      throw Exception(
          'Failed to add part. Status code: ${response.statusCode}');
    }
  }

  static Future<PartModel?> getPartById(String partId) async {
    String baseUrl = await _getServerUrl();

    // Corrected URL format with partId as a query parameter
    var url = Uri.parse('$baseUrl/get_part_by_id/$partId');

    var response = await http.get(url);

    if (response.statusCode == 200) {
      // Decode the JSON response body
      var responseBody = jsonDecode(response.body);

      // Assuming PartModel has a `fromJson` constructor to deserialize JSON
      PartModel part = PartModel.fromJson(responseBody);

      return part;
    } else {
      print('Failed to load part: ${response.statusCode}');
      return null; // Return null if the request fails
    }
  }

  static Future<PartModel?> getPartByDetails({
    String? partId,
    String? partName,
    String? partNumber,
  }) async {
    String baseUrl = await _getServerUrl();

    // Construct the URL with conditional query parameters
    var queryParameters = <String, String>{};
    if (partId != null && partId.isNotEmpty) {
      queryParameters['part_id'] = partId;
    }
    if (partName != null && partName.isNotEmpty) {
      queryParameters['part_name'] = partName;
    }
    if (partNumber != null && partNumber.isNotEmpty) {
      queryParameters['part_number'] = partNumber;
    }

    // Ensure that at least one parameter is provided
    if (queryParameters.isEmpty) {
      throw Exception(
          'At least one of partId, partName, or partNumber must be provided.');
    }

    // Construct the full URL
    var url = Uri.parse('$baseUrl/get_part_by_details')
        .replace(queryParameters: queryParameters);

    // Send the GET request
    var response = await http.get(url);

    // Check for a successful response
    if (response.statusCode == 200) {
      // Decode the JSON response body
      var responseBody = jsonDecode(response.body);

      // Assuming PartModel has a `fromJson` constructor to deserialize JSON
      PartModel part = PartModel.fromJson(responseBody);

      return part;
    } else {
      print('Failed to load part: ${response.statusCode}');
      return null; // Return null if the request fails
    }
  }
}
