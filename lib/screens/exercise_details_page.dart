import 'package:flutter/material.dart';

// page for recommended exercise information
class ExerciseRecommendationDetailPage extends StatelessWidget {
  final String name;
  final String secondaryMuscles;
  final String predictedLevel;
  final String instructions;

  const ExerciseRecommendationDetailPage({
    super.key,
    required this.name,
    required this.secondaryMuscles,
    required this.predictedLevel,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Exercise Name: $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Secondary Muscles: $secondaryMuscles',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Predicted Level: $predictedLevel',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Instructions: $instructions',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
