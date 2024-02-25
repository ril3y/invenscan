<<<<<<< HEAD

import "package:invenscan/utils/api/location.dart";

class PartModel {
  final String? partId;
=======
import "package:basic_websocket/utils/api/location.dart";

class PartModel {
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  final String? partNumber;
  final String? partName;
  final int? quantity;
  final String? description;
  final String? supplier;
<<<<<<< HEAD
  final Location? location;
  final String? image_path; // Change the type to String
  final Map<String, dynamic> additionalProperties; // Add this field

  PartModel({
    this.partId,
=======
  // Assuming LocationModel is already defined in Dart
  final Location? location;

  PartModel({
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
    this.partNumber,
    this.partName,
    this.quantity,
    this.description,
    this.supplier,
    this.location,
<<<<<<< HEAD
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
=======
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      partNumber: json['part_number'],
      partName: json['part_name'],
      quantity: json['quantity'],
      description: json['description'],
      supplier: json['supplier'],
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
    );
  }

  Map<String, dynamic> toJson() {
<<<<<<< HEAD
    // Start with adding all explicit properties
    final data = {
      'part_id': partId,
=======
    return {
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
      'part_number': partNumber,
      'part_name': partName,
      'quantity': quantity,
      'description': description,
      'supplier': supplier,
      'location': location?.toJson(),
<<<<<<< HEAD
      'image_path': image_path,
    };

    // Add all additional properties
    data.addAll(additionalProperties);

    return data;
  }

  static List<PartModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => PartModel.fromJson(json)).toList();
=======
    };
  }

  bool validate() {
    return partNumber != null || partName != null;
>>>>>>> 7ec393b37ce2c1e0d82742684585db5e255a7133
  }
}
