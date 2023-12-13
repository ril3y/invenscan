class BasePart {
  String? partNumber;
  String? supplier_part_number;
  String? category;
  String? description;
  String? units;
  String? imageURL;

  // A map to hold dynamic properties
  Map<String, dynamic> additionalProperties = {};

  @override
  void addProperty(String key, dynamic value) {
    additionalProperties[key] = value;
  }
}