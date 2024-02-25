class CategoryTypeAssociations {
  static const Map<String, List<String>> associations = {
    'Hardware': ['Screw', 'Nut', 'Bolt', 'Fastener'],
    'Component': ['Resistor', 'Inductor', 'Capacitor', 'Connector', 'Microcontroller', 'IC'],
    'Tool':['Drill Bit','End Mill']
    // Add more categories and associated types here
  };

  static List<String> getTypesForCategory(String category) {
    return associations[category] ?? [];
  }
}
