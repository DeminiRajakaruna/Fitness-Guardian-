import 'package:fitnessguardian/screens/exercise_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fitnessguardian/websocket/websocket.dart';

// page for exercise recommendation
class ExerciseRecommendationPage extends StatefulWidget {
  const ExerciseRecommendationPage({Key? key}) : super(key: key);

  @override
  _ExerciseRecommendationPageState createState() =>
      _ExerciseRecommendationPageState();
}

class _ExerciseRecommendationPageState extends State<ExerciseRecommendationPage> {
  //define variables
  String? selectedBodyPart;
  String? selectedEquipment;
  String? selectedTarget;

  final List<String> bodyParts = [
    'waist',
    'upper legs',
    'back',
    'lower legs',
    'chest',
    'upper arms',
    'cardio',
    'shoulders',
    'lower arms',
    'neck',
  ];
  final List<String> equipments = [
    'body weight',
    'cable',
    'leverage machine',
    'assisted',
    'medicine ball',
    'stability ball',
    'band',
    'barbell',
    'rope',
    'dumbbell',
  ];

  final List<String> targets = [
    'abs',
    'quads',
    'lats',
    'calves',
    'pectorals',
    'glutes',
    'hamstrings',
    'adductors',
    'triceps',
    'cardiovascular system',
  ];

  late WebSocket _webSocket;

  List<Map<String, dynamic>> recommendations = [];

  @override
  void initState() {
    super.initState();
    _webSocket = WebSocket();
  }

  // function to update UI based on the feedback recieved
  void _handleMessageReceived(dynamic message) {
    setState(() {
      final String? name = message['name'] ?? '';
      final String? secondaryMuscles = message['secondaryMuscles'] ?? '';
      final String? predictedLevel = message['predictedLevel'] ?? '';
      final String? instructions = message['instructions'] ?? '';

      recommendations.clear();

      recommendations.add({
        'name': name,
        'secondaryMuscles': secondaryMuscles,
        'predictedLevel': predictedLevel,
        'instructions': instructions,
      });

      print('Exercise Name: $name');
      print('Secondary Muscles: $secondaryMuscles');
      print('Predicted Level: $predictedLevel');
      print('Instructions: $instructions');
    });
  }
  // send selected user data to backend using websocket
  void _sendExerciseData() {
    if (selectedBodyPart == null ||
        selectedEquipment == null ||
        selectedTarget == null) {
      return;
    }

    _webSocket.sendExercise({
      'bodyPart': selectedBodyPart,
      'equipment': selectedEquipment,
      'target': selectedTarget,
    }, _handleMessageReceived);

    print('Sending exercise data to backend');
  }

  // widget builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Recommendations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown('Body Part', selectedBodyPart, bodyParts,
                (value) => selectedBodyPart = value),
            const SizedBox(height: 10),
            _buildDropdown('Equipment', selectedEquipment, equipments,
                (value) => selectedEquipment = value),
            const SizedBox(height: 10),
            _buildDropdown('Target', selectedTarget, targets,
                (value) => selectedTarget = value),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendExerciseData,
              child: const Text('Send'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildRecommendedExerciseList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String labelText, String? selectedValue,
      List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      value: selectedValue,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRecommendedExerciseList() {
    return ListView.builder(
      itemCount: recommendations.length,
      itemBuilder: (BuildContext context, int index) {
        final exercise = recommendations[index];
        final String name = exercise['name'] ?? '';
        final String secondaryMuscles = exercise['secondaryMuscles'] ?? '';
        final String predictedLevel = exercise['predictedLevel'] ?? '';
        final String instructions = exercise['instructions'] ?? '';

        return ListTile(
          title: Text(name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secondary Muscles: $secondaryMuscles'),
              Text('Predicted Level: $predictedLevel'),
              Text('Instructions: $instructions'),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseRecommendationDetailPage(
                  name: name,
                  secondaryMuscles: secondaryMuscles,
                  predictedLevel: predictedLevel,
                  instructions: instructions,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
