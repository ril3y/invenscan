// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import '../part_data.dart';
import 'edit_screen.dart';

class CustomTableScreen extends StatefulWidget {
  const CustomTableScreen({Key? key}) : super(key: key);

  @override
  _CustomTableScreenState createState() => _CustomTableScreenState();
}

class _CustomTableScreenState extends State<CustomTableScreen> {
  List<PartData> parts = []; // Populate this list with your parts data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts Table'),
      ),
      body: buildCustomTable(parts),
    );
  }

  static Widget buildCustomTable(List<PartData> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: PartData.createColumns().map((column) {
            return Expanded(
              child: Text(
                column.label.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data Rows
        Expanded(
          child: ListView.builder(
            itemCount: parts.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EditPartScreen(part: parts[index]),
                  ));
                },
                child: Container(
                  color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: PartData.createRowCells(parts[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}