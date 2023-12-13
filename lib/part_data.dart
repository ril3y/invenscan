class PartData {
  final String supplierPn;
  final String manufacturerPn;
  final Map<String, dynamic> additionalData; // To store dynamic data

  PartData(this.supplierPn, this.manufacturerPn, this.additionalData);

  factory PartData.fromJson(Map<String, dynamic> json) {
    // Extract guaranteed fields
    var supplierPn = json['supplier_pn'] as String;
    var manufacturerPn = json['manufacturer_pn'] as String;

    // Remove guaranteed fields and keep the rest as additional data
    json.remove('supplier_pn');
    json.remove('manufacturer_pn');

    return PartData(supplierPn, manufacturerPn, json);
  }
}
