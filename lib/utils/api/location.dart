

class Location {
  final String id;
  final String name;
  final String description;
  final String? parentId; // Nullable
    bool childrenLoaded = false;


  Location({required this.id, required this.name, required this.description, this.parentId});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      description: json['description'],
      name: json['name'],
      parentId: json['parent_id'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description':description,
      'parent_id': parentId,
    };
  }
}
