// Define a class to represent a user input requirement.
class UserInputRequirement {
  final String name; // Name of the input, like 'quantity' or 'type'.
  final Type type; // The expected data type for this input, e.g., int, String.
  final String description; // A brief description of the input.

  UserInputRequirement({required this.name, required this.type, this.description = ""});
}