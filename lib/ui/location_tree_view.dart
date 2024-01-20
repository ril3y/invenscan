import 'package:animated_tree_view/animated_tree_view.dart' as atv;
import 'package:basic_websocket/utils/api/server_api.dart';
import 'package:basic_websocket/utils/api/location.dart';

class LocationTreeView extends StatefulWidget {
  final Function(Location) onLocationSelected;

  const LocationTreeView({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationTreeViewState createState() => _LocationTreeViewState();
}

class _LocationTreeViewState extends State<LocationTreeView> {
  List<Location> topLevelLocations = [];

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



  atv.Node<Location> _buildNode(Location location) {
    return atv.Node<Location>(
      key: ValueKey(location.id),
      content: location.name,
      children: location.children.map(_buildNode).toList(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tree'),
      ),
      body: topLevelLocations.isEmpty
          ? Center(child: CircularProgressIndicator())
          : atv.AnimatedTreeView<Location>(
              nodes: topLevelLocations.map(_buildNode).toList(),
              onNodeTap: (node) {
                widget.onLocationSelected(node.content);
              },
            ),
    );
  }
}
