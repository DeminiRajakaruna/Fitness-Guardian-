import 'package:flutter/material.dart';
import 'package:fitnessguardian/screens/diet_details_page.dart';
import 'package:fitnessguardian/websocket/websocket.dart';

// page for diet recommendation
class DietRecommendationPage extends StatefulWidget {
  const DietRecommendationPage({Key? key}) : super(key: key);

  @override
  _DietRecommendationPageState createState() => _DietRecommendationPageState();
}

class _DietRecommendationPageState extends State<DietRecommendationPage> {
  // variables
  String? selectedAgeValue;
  String? selectedWeightValue;
  String? selectedHeightValue;
  String? selectedGenderValue;
  String? selectedActivityLevelValue;

  final List<String> ages =
      List.generate(90, (index) => (index + 1).toString());
  final List<String> weights =
      List.generate(8, (index) => (index * 10 + 10).toString());
  final List<String> heights = [
    '0.8',
    '0.9',
    '1.0',
    '1.1',
    '1.2',
    '1.3',
    '1.4',
    '1.5',
    '1.6'
  ];
  final List<String> activityLevels =
      List.generate(8, (index) => (index * 0.1 + 1.2).toString());
  final List<String> genders = ['M', 'F'];

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
      final String? predictedCalorie = message['predictedCalorie'] ?? '';
      final String recommendedIngredients =
          message['recommendedIngredients'] ?? '';

      List<String> ingredientsList;

      if (recommendedIngredients.isNotEmpty) {
        ingredientsList = recommendedIngredients.split('\n');
      } else {
        ingredientsList = ['No ingredients available'];
      }

      recommendations.clear();

      recommendations.add({
        'calorie': predictedCalorie,
        'ingredients': ingredientsList,
      });

      print('Predicted Calorie: $predictedCalorie');
      print('Recommended Ingredients: $ingredientsList');
    });
  }

  // send selected user data to backend using websocket
  void _sendDietData() {
    _webSocket.sendDiet({
      'age': selectedAgeValue,
      'weight': selectedWeightValue,
      'height': selectedHeightValue,
      'gender': selectedGenderValue,
      'activity_level': selectedActivityLevelValue,
    }, _handleMessageReceived);

    print('Sending diet data to backend');
  }

  // widget builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Recommendations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown('Age', selectedAgeValue, ages,
                (value) => selectedAgeValue = value),
            const SizedBox(height: 10),
            _buildDropdown('Weight', selectedWeightValue, weights,
                (value) => selectedWeightValue = value),
            const SizedBox(height: 10),
            _buildDropdown('Height', selectedHeightValue, heights,
                (value) => selectedHeightValue = value),
            const SizedBox(height: 10),
            _buildDropdown('Gender', selectedGenderValue, genders,
                (value) => selectedGenderValue = value),
            const SizedBox(height: 10),
            _buildDropdown('Activity Level', selectedActivityLevelValue,
                activityLevels, (value) => selectedActivityLevelValue = value),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendDietData,
              child: const Text('Send'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: _buildRecommendedDietList(),
            ),
          ],
        ),
      ),
    );
  }

  // widget for building dropdown choice boxes
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

  // widget to show recommended diet 
  Widget _buildRecommendedDietList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: recommendations.length,
      itemBuilder: (BuildContext context, int index) {
        final String calorie = recommendations[index]['calorie']!;
        final List<String> ingredients =
            recommendations[index]['ingredients'] as List<String>;

        return ListTile(
          title: Text('Calorie: $calorie'),
          subtitle: Text('Ingredients: ${ingredients.join(", ")}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DietRecommendationDetailPage(
                  calorie: calorie,
                  ingredients: ingredients.join("\n"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
