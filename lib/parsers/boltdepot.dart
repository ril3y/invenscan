import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../utils/barcode_parser.dart';
import '../utils/user_input_requirement.dart';

class BoltDepotParser extends BarcodeParser {
  final RegExp _pattern =
      RegExp(r"http://boltdepot.com/Product-Details.aspx\?product=");

  @override
  List<UserInputRequirement> get requiredUserInputs => [
        UserInputRequirement(name: 'quantity', type: int),
        UserInputRequirement(name: 'type', type: String),
        UserInputRequirement(name: 'description', type: String),
      ];

  @override
  bool matches(List<int> byteData) {
    String byteString = utf8.decode(byteData);
    return _pattern.hasMatch(byteString);
  }

  void _extractProperties(Document document) {
    document
        .querySelectorAll('.product-details-table .property-name')
        .forEach((element) {
      var key = element.text.trim();
      var value =
          element.nextElementSibling?.querySelector('span')?.text.trim();
      if (value != null) {
        switch (key) {
          case 'Category':
            partType = value; // Socket Screws etc.
            break;

          default:
            // For all other keys, add them to the additionalProperties map
            addProperty(key, value);
            break;
        }
      }
    });
  }

  @override
  Future<dynamic> enrich() async {
    try {
      // Construct the URL based on the part number
      var url =
          'https://www.boltdepot.com/Product-Details.aspx?product=$partNumber';

      // Make an HTTP request to fetch part details
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        // Extract the common description
        description = document.querySelector('.header-title h1')!.text;
        imageURL =
            "https://www.boltdepot.com/${document.querySelector('#ctl00_ctl00_Body_Body__ctrl_0_CatalogImage')!.attributes['src']!}";

        // Extract properties
        _extractProperties(document);

        // Return the enriched BoltDepotPart object
        return this;
      } else {
        throw Exception('Failed to load product page');
      }
    } catch (e) {
      // Handle any errors and return null or an error message
      print('Error enriching data: $e');
      return null;
    }
  }

  @override
  dynamic parse(List<int> byteData) {
    try {
      // Decode the hexadecimal string first
      String decodedData = utf8.decode(byteData);
      // Parse the decoded data as a URI
      var uri = Uri.parse(decodedData);

      String? partNumberFromURL = uri.queryParameters['product'];
      partVendor = "Bolt Depot";

      if (partNumberFromURL != null) {
        // Set the extracted part number
        partNumber = partNumberFromURL;

        // Set the part URL
        partURL = decodedData;
        addCategory("Hardware");
      }

      // Return a structured response or the extracted data
      return this;
    } catch (e) {
      print("Error parsing byte data: $e");
      return null;
    }
  }
}
