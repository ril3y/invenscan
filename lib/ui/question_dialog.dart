import 'package:flutter/material.dart';
import 'dart:convert';

class QuestionsDialog extends StatelessWidget {
  final String jsonData;

  const QuestionsDialog({Key? key, required this.jsonData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the JSON data
    var data = jsonDecode(jsonData);
    String event = data['event'];

    // Ensure that the event is a question
    if (event != 'question') {
      return Container(); // or some error widget
    }

    // Extract question details from questionData
    String question = data['question_text'];
    String positiveResponse = data['positive_text'];
    String negativeResponse = data['negative_text'];

    return AlertDialog(
      title: const Text('Question'),
      content: Text(question),
      actions: <Widget>[
        TextButton(
          child: Text(negativeResponse),
          onPressed: () {
            Navigator.of(context).pop(false); // Return 'false' when negative response is pressed
          },
        ),
        TextButton(
          child: Text(positiveResponse),
          onPressed: () {
            Navigator.of(context).pop(true); // Return 'true' when positive response is pressed
          },
        ),
      ],
    );
  }
}
