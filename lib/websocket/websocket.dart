// ignore_for_file: avoid_print, library_prefixes

import 'dart:convert';
import 'dart:io';

import 'package:fitnessguardian/models/pose_feedback.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocket {
  late IO.Socket socket;
  final String url = 'http://localhost:5000'; // Server URL

  WebSocket() {
    _initializeSocket();
  }

  void _initializeSocket() {
    // credentials to connect to backend
    socket = IO.io(
      url,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'options': <String, dynamic>{
          'maxHttpBufferSize': 100000000, // 100MB
        },
      },
    );
    socket.connect();
  }

  // send user diet preference to backend
  void sendDiet(Map<String, dynamic> dietData,
      void Function(dynamic message) dietCallback) {
    try {
      _ensureConnected();
      _setupDietListener(dietCallback);
      socket.emit('sendDiet', dietData);
    } catch (e) {
      print('Error sending diet data: $e');
    }
  }

  // send user login credentials to backend
  void sendUser(
      String email, String password, void Function(bool) userCallback) {
    try {
      _ensureConnected();
      _setupUserAuthListener(userCallback);
      socket.emit('sendUser', {'username': email, 'userpassword': password});
    } catch (e) {
      print('Error sending user authentication request: $e');
    }
  }

  // send user exercise video to backend
  void sendVideo(
    File videoFile,
    String videoName,
    String? selectedExerciseType,
    void Function(dynamic message) videoCallback,
  ) async {
    try {
      _ensureConnected();
      _setupVideoListener(videoCallback);
      final List<int> videoBytes = await videoFile.readAsBytes();
      final String base64Video = base64Encode(videoBytes);
      socket.emit('sendVideo', {
        'name': videoName,
        'file': base64Video,
        'type': selectedExerciseType,
      });
    } catch (e) {
      print('Error sending video: $e');
    }
  }

  // informing backend to stop video process
  void stopStream(){
    socket.emit('stopStream', {'status':'stop stream'});
  }

  // send user exercise preference to backend
  void sendExercise(Map<String, dynamic> exerciseData,
      void Function(dynamic message) exerciseCallback){
      try {
      _ensureConnected();
      _setupExerciseListener(exerciseCallback);
      socket.emit('sendExercise', exerciseData);
    } catch (e) {
      print('Error sending exercise data: $e');
    }
  }

  // recieve exercise recommendation
  void _setupExerciseListener(void Function(dynamic message) exerciseCallback){
    socket.on('exerciseRecommendation', (dynamic data) {
      print('exercise recommendation received');
      exerciseCallback(data);
    });
  }
  
  // recieve diet recommendation
  void _setupDietListener(void Function(dynamic message) dietCallback) {
    socket.on('dietRecommendation', (dynamic data) {
      print('Diet recommendation received');

      final dynamic recommendationData = data;

      if (recommendationData is Map<String, dynamic>) {
        final String predictedCalorie =
            recommendationData['predicted_calorie'].toString();
        final String recommendedIngredients =
            recommendationData['recommended_ingredients'].toString();

        final Map<String, dynamic> dietInfo = {
          'predictedCalorie': predictedCalorie,
          'recommendedIngredients': recommendedIngredients.isNotEmpty
              ? recommendedIngredients
              : 'No ingredients available',
        };

        dietCallback(dietInfo);
      }
    });
  }

  // recieve posture analysis
  void _setupVideoListener(void Function(dynamic message) videoCallback) {
    socket.on('posefeedbackdata', (dynamic jsonFile) {
      print('Video feedback received');

      final dynamic data = jsonFile;

      if (data is Map<String, dynamic>) {
        final String type = data['type'];
        final String imageBase64 = data['image'];
        final String header = data['header'];
        final String description = data['description'];

        if (type == 'wrong') {
          final PoseFeedbackData poseFeedback = PoseFeedbackData(
            imageBytes: base64.decode(imageBase64),
            header: header,
            description: description,
          );
          videoCallback(poseFeedback);
        } else if (type == 'stream') {
          videoCallback(base64.decode(imageBase64));
        }
      }
    });
  }

  // recieve user authentication status
  void _setupUserAuthListener(void Function(bool) userCallback) {
    socket.on('userAuthentication', (dynamic data) {
      print('User authentication response received');

      if (data is Map<String, dynamic>) {
        final String status = data['status'];

        if (status == 'success') {
          userCallback(true);
        } else {
          userCallback(false);
        }
      }
    });
  }

  // ensure websocket is connected
  void _ensureConnected() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  // end websocket connection
  void close() {
    socket.disconnect();
  }
}
