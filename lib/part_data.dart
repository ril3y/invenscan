import 'package:flutter/material.dart';

class PartData {
  final String supplier;
  final String partNumber;
  final int quantity; // Assuming quantity is an integer
  final Map<String, dynamic> jsonData; // Store the full JSON data

  PartData(this.supplier, this.partNumber, this.quantity, this.jsonData);

  factory PartData.fromJson(Map<String, dynamic> json) {
    var supplier = json['supplier'] as String;
    var partNumber = json['part_number'] as String;
    var quantity = json['quantity'] as int; // Extract quantity from JSON
    var jsonData = json;
    return PartData(supplier, partNumber, quantity,
        json); // Pass the entire JSON to the constructor
  }

  static List<DataColumn> createColumns() {
    return const [
      DataColumn(
          label: Text(
        'Supplier',
        style: TextStyle(fontSize: 10),
      )),
      DataColumn(
          label: Text(
        'Part Number',
        style: TextStyle(fontSize: 10),
      )),
      DataColumn(
          label: Text(
        'Quantity',
        style: TextStyle(fontSize: 10),
      )),
      DataColumn(
          label: Text(
        'Actions',
        style: TextStyle(fontSize: 10),
      )), // New column for actions like edit
    ];
  }

  // Added method to create row cells
  static List<Widget> createRowCells(PartData part) {
    return [
      Text(part.supplier),
      Text(part.partNumber),
      Text(part.quantity.toString()), // Display quantity
      // Add more cells as needed based on other properties
    ];
  }

  static List<DataRow> createRows(
      List<PartData> parts, void Function(PartData) onTapRow) {
    return parts.map<DataRow>((part) {
      return DataRow(
        cells: part.toDataCells(onTapRow),
      );
    }).toList();
  }

  List<DataCell> toDataCells(void Function(PartData) onTap) {
    return [
      DataCell(Text(supplier)),
      DataCell(Text(partNumber)),
      DataCell(Text(quantity.toString())),
      DataCell(
        InkWell(
          onTap: () => onTap(this),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit'),
              Icon(Icons.edit, size: 16), // Adding an edit icon
            ],
          ),
        ),
      ),
    ];
  }
}
