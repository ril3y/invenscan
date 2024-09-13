// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:invenscan/ui/add_parts/edit_screen.dart';
import 'package:invenscan/utils/api/partmodel.dart';
import 'package:invenscan/utils/api/server_api.dart';
import 'package:invenscan/ui/add_parts/view_part.dart';

class PartPage extends StatefulWidget {
  const PartPage({super.key});

  @override
  _PartPageState createState() => _PartPageState();
}

class _PartPageState extends State<PartPage> {
  Future<List<PartModel>>? partsFuture;
  int currentPartCount = 10; // Default part count

  @override
  void initState() {
    super.initState();
    _loadParts(currentPartCount);
  }

  void _loadParts(int partCount) {
    partsFuture = ServerApi.getParts(1, partCount);
  }

  void _showPartActions(BuildContext context, PartModel part) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(part.partName ?? 'Part Actions'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                // Implement navigation or functionality for editing the part
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditPartScreen(
                            part: part,
                          )), // Replace EditPartScreen() with your actual widget
                );
              },
              child: const Text('Edit'),
            ),
            SimpleDialogOption(
              onPressed: () {
                // Navigate to ViewPartScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewPartScreen(part: part)),
                );
              },
              child: const Text('View'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog first
                try {
                  await ServerApi.deletePart(part.partId!);
                  // Refresh the parts list
                  setState(() {
                    partsFuture = ServerApi.getParts(1, currentPartCount);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Part deleted successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to delete part")),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartsTable(List<PartModel> parts) {
    return ListView.builder(
      itemCount: parts.length,
      itemBuilder: (context, index) {
        PartModel part = parts[index];

        Widget leadingWidget =
            part.image_path != null && part.image_path!.isNotEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(28),
                      image: DecorationImage(
                        image: NetworkImage(part.image_path!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.inventory, size: 24),
                  );

        return Dismissible(
          key: Key(
              part.partNumber ?? 'part-$index'), // Ensure this key is unique
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            // Call the API to delete the part
            try {
              await ServerApi.deletePart(
                  part.partId!); // Adapt with your actual API method
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Part deleted successfully")),
              );
              // Optionally, refresh your parts list here
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to delete part")),
              );
            }
          },
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirm"),
                  content:
                      const Text("Are you sure you wish to delete this item?"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("DELETE"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("CANCEL"),
                    ),
                  ],
                );
              },
            );
          },
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: AlignmentDirectional.centerEnd,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            child: ListTile(
              leading: leadingWidget,
              title: Text(
                part.partNumber ?? 'No Number',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                part.description ?? 'No Description',
                style: const TextStyle(fontSize: 12.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showPartActions(
                  context, part), // Placeholder for actual action handling
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Parts',
                hintText: 'Enter part name or number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) async {
                if (value.isEmpty) {
                  setState(() {
                    partsFuture = ServerApi.getParts(1, currentPartCount);
                  });
                } else {
                  try {
                    var searchResults = await ServerApi.performSearch(value,
                        "part"); // Adjust "part" based on your API's searchType parameter
                    setState(() {
                      partsFuture = Future.value(searchResults['searchResults']
                          .map<PartModel>(
                              (result) => PartModel.fromJson(result))
                          .toList());
                    });
                  } catch (e) {
                    print(e); // Consider handling errors more gracefully
                  }
                }
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PartModel>>(
              future: partsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error.toString()}'));
                } else if (snapshot.hasData) {
                  // Ensure _buildPartsTable is prepared to handle the data correctly
                  return _buildPartsTable(snapshot.data!);
                } else {
                  return const Center(child: Text('No parts found'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            partsFuture = ServerApi.getParts(1, currentPartCount);
          });
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<int>(
            value: currentPartCount,
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  currentPartCount = newValue;
                  _loadParts(currentPartCount);
                });
              }
            },
            items: <int>[10, 20, 50, 100, -1] // -1 for 'All'
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value == -1 ? 'All' : value.toString()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
