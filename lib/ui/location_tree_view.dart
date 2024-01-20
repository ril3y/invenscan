import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/utils/api/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


const showSnackBar = false;
const expandChildrenOnReady = true;

final Map<int, Color> colorMapper = {
  0: Colors.white,
  1: Colors.blueGrey[50]!,
  2: Colors.blueGrey[100]!,
  3: Colors.blueGrey[200]!,
  4: Colors.blueGrey[300]!,
  5: Colors.blueGrey[400]!,
  6: Colors.blueGrey[500]!,
  7: Colors.blueGrey[600]!,
  8: Colors.blueGrey[700]!,
  9: Colors.blueGrey[800]!,
  10: Colors.blueGrey[900]!,
};

extension ColorUtil on Color {
  Color byLuminance() =>
      this.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
}

class LocationTreeView extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const LocationTreeView({Key? key, required this.onLocationSelected}) : super(key: key);

  _LocationTreeViewState createState() => _LocationTreeViewState();
  
}

class _LocationTreeViewState extends State<LocationTreeView> {
  List<Location> topLevelLocations = [];
  TreeViewController? _controller;

  @override
  void initState() {
    super.initState();
    // Initialization logic will be added here later
    _fetchTopLevelLocations();
  }

  void _fetchTopLevelLocations() async {
    try {
      var locations = await ServerApi.fetchLocations();
      setState(() {
        topLevelLocations = locations;
      });
    } catch (e) {
      // Handle errors, e.g., by showing a snackbar or logging
      print('Failed to fetch top-level locations: $e');
    }
  }



  // atv.Node<Location> _buildNode(Location location) {
  //   return atv.Node<Location>(
  //     key: ValueKey(location.id),
  //     content: location.name,
  //     children: location.children.map(_buildNode).toList(),
  //   );
  // }



 @override
  Widget build(BuildContext context) {
    return Scaffold(

      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: sampleTree.expansionNotifier,
        builder: (context, isExpanded, _) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (sampleTree.isExpanded) {
                _controller?.collapseNode(sampleTree);
              } else {
                _controller?.expandAllChildren(sampleTree);
              }
            },
            label: isExpanded
                ? const Text("Collapse all")
                : const Text("Expand all"),
          );
        },
      ),
      body: TreeView.simple(
        tree: sampleTree,
        showRootNode: true,
        expansionIndicatorBuilder: (context, node) =>
            ChevronIndicator.rightDown(
          tree: node,
          color: Colors.blue[700],
          padding: const EdgeInsets.all(8),
        ),
        indentation: const Indentation(style: IndentStyle.squareJoint),
        onItemTap: (item) {
          if (kDebugMode) print("Item tapped: ${item.key}");

          if (showSnackBar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Item tapped: ${item.key}"),
                duration: const Duration(milliseconds: 750),
              ),
            );
          }
        },
        onTreeReady: (controller) {
          _controller = controller;
          if (expandChildrenOnReady) controller.expandAllChildren(sampleTree);
        },
        builder: (context, node) => Card(
          color: colorMapper[node.level.clamp(0, colorMapper.length - 1)]!,
          child: ListTile(
            title: Text("Item ${node.level}-${node.key}"),
            subtitle: Text('Level ${node.level}'),
          ),
        ),
      ),
    );
  }
}

final sampleTree = TreeNode.root()
  ..addAll([
    TreeNode(key: "0A")..add(TreeNode(key: "0A1A")),
    TreeNode(key: "0C")
      ..addAll([
        TreeNode(key: "0C1A"),
        TreeNode(key: "0C1B"),
        TreeNode(key: "0C1C")
          ..addAll([
            TreeNode(key: "0C1C2A")
              ..addAll([
                TreeNode(key: "0C1C2A3A"),
                TreeNode(key: "0C1C2A3B"),
                TreeNode(key: "0C1C2A3C"),
              ]),
          ]),
      ]),
    TreeNode(key: "0D"),
    TreeNode(key: "0E"),
  ]);