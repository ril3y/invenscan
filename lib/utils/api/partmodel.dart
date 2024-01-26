import "package:basic_websocket/utils/api/location.dart";

class PartModel {
  final String? partNumber;
  final String? partName;
  final int? quantity;
  final String? description;
  final String? supplier;
  // Assuming LocationModel is already defined in Dart
  final Location? location;

  PartModel({
    this.partNumber,
    this.partName,
    this.quantity,
    this.description,
    this.supplier,
    this.location,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_number': partNumber,
      'part_name': partName,
      'quantity': quantity,
      'description': description,
      'supplier': supplier,
      'location': location?.toJson(),
    };
  }

  bool validate() {
    return partNumber != null || partName != null;
  }
}
