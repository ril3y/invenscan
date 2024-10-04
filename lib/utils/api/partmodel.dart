import "package:invenscan/utils/api/category.dart";
import "package:invenscan/utils/api/location.dart";

class PartModel {
  String? partId;
  String? partNumber;
  String? partType;
  String? partName;
  int? quantity;
  String? description;
  String? supplier;
  Location? location;
  String? image_path; // Change the type to String
  Map<String, dynamic> additional_properties;
  List<Category>? categories;

  PartModel({
    this.partId,
    this.partNumber,
    this.partName,
    this.partType,
    this.quantity,
    this.description,
    this.supplier,
    this.location,
    this.image_path,
    this.additional_properties = const {},
    this.categories,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    // Explicit properties
    final explicitProperties = {
      'part_number',
      'part_name',
      'part_type',
      'quantity',
      'description',
      'supplier',
      'part_id',
      'location',
      'image_path',
      'categories',
    };

    // Parse the categories
    List<Category> categories = [];
    if (json.containsKey('categories')) {
      final categoriesJson = json['categories'];

      if (categoriesJson is List) {
        categories = categoriesJson
            .where((category) => category is Map<String, dynamic>)
            .map((categoryJson) => Category.fromJson(categoryJson))
            .toList();
      } else if (categoriesJson is String) {
        // Handle comma-separated categories string if needed
        categories = categoriesJson.split(',').map((categoryName) {
          return Category(
              id: '',
              name: categoryName.trim()); // Assuming categories don't have IDs
        }).toList();
      }
    }

    // Filter json to get only additional properties
    final additional = Map<String, dynamic>.from(json)
      ..removeWhere((key, value) => explicitProperties.contains(key));

    return PartModel(
      partNumber: json['part_number'],
      partName: json['part_name'],
      quantity: json.containsKey('quantity') ? json['quantity'] : null,
      description: json['description'],
      supplier: json['supplier'],
      partId: json['part_id'],
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      image_path: json['image_path'],
      additional_properties: json['additional_properties'] as Map<String, dynamic>? ?? {},

      categories: categories, // Include parsed categories
    );
  }

   Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'part_id': partId,
      'part_number': partNumber,
      'part_name': partName,
      'quantity': quantity,
      'description': description,
      'supplier': supplier,
      'location': location?.toJson(),
      'image_path': image_path,
    };

    data['additional_properties'] = additional_properties;  // Ensure additional_properties is added
    return data;
  }
}
