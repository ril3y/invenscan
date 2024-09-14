
import "package:invenscan/utils/api/location.dart";

class PartModel {
   String? partId;
   String? partNumber;
   String? partName;
   int? quantity;
   String? description;
   String? supplier;
   Location? location;
   String? image_path; // Change the type to String
   Map<String, dynamic> additionalProperties; // Add this field

  PartModel({
    this.partId,
    this.partNumber,
    this.partName,
    this.quantity,
    this.description,
    this.supplier,
    this.location,
    this.image_path,
    this.additionalProperties = const {},
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    // Explicit properties
    final explicitProperties = {
      'part_number',
      'part_name',
      'quantity',
      'description',
      'supplier',
      'part_id',
      'location',
      'image_path',
    };

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
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      image_path: json['image_path'],
      additionalProperties: additional, // Pass the filtered additional properties
    );
  }

  Map<String, dynamic> toJson() {
    // Start with adding all explicit properties
    final data = {
      'part_id': partId,
      'part_number': partNumber,
      'part_name': partName,
      'quantity': quantity,
      'description': description,
      'supplier': supplier,
      'location': location?.toJson(),
      'image_path': image_path,
    };

    // Add all additional properties
    data.addAll(additionalProperties);

    return data;
  }

  static List<PartModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => PartModel.fromJson(json)).toList();
  }
}
