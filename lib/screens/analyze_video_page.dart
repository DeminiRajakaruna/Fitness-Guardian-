// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'dart:io';
import 'package:fitnessguardian/screens/pose_details_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitnessguardian/websocket/websocket.dart';
import 'package:fitnessguardian/models/pose_feedback.dart';

// analyze video page
class AnalyzeVideoPage extends StatefulWidget {
  const AnalyzeVideoPage({super.key});

  @override
  _AnalyzeVideoPageState createState() => _AnalyzeVideoPageState();
}

class _AnalyzeVideoPageState extends State<AnalyzeVideoPage> {
  // variables
  String? _videoPath;
  String? _videoName;
  String? _selectedExerciseType;
  late Uint8List? _videoStream;
  late WebSocket _webSocket;
  final List<PoseFeedbackData> _feedbackList = [];
  final List<String> _dropdownItems = [
    'Pushup',
    'Situp',
    'Squat',
    'Pullup',
    'Mountain Climbing',
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _webSocket = WebSocket();
    _videoStream = null;
  }

  @override
  void dispose() {
    _webSocket.close();
    super.dispose();
  }

  // requesting storage permission for video selection
  void _requestPermissions() async {
    final status = await Permission.mediaLibrary.request();
    if (status.isGranted) {
      print('Permission granted');
    } else {
      print('Permission denied');
    }
  }

  // function for picking video
  void _pickVideo() async {
    _removeVideo();

    setState(() {
      _feedbackList.clear();
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
    );
    if (result != null) {
      setState(() {
        _videoPath = result.files.single.path!;
        _videoName = result.files.single.name;
      });
    }
    _webSocket.sendVideo(
      File(_videoPath!),
      _videoName!,
      _selectedExerciseType,
      _handleMessageReceived,
    );
  }

  // call back function for updating UI based on feedback
  void _handleMessageReceived(dynamic message) {
    setState(() {
      if (message is PoseFeedbackData) {
        _feedbackList.add(message);
      } else if (message is Uint8List) {
        _videoStream = message;
      }
    });
  }

  // removing video from UI
  void _removeVideo() {
    setState(() {
      _videoPath = null;
      _videoName = null;
      _videoStream = null;
      _webSocket.stopStream();
    });
  }

  // turncating description 
  String _truncateDescription(String description, {int maxLength = 30}) {
    return description.length > maxLength
        ? '${description.substring(0, maxLength)}...'
        : description;
  }

  // widget builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posture Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExerciseTypeSelector(),
            const SizedBox(height: 10),
            _buildVideoPlayer(),
            const SizedBox(height: 10),
            _buildButtonsRow(),
            const SizedBox(height: 10),
            _buildFeedbackInfo(),
            const SizedBox(height: 10),
            Expanded(
              child: buildListBuilder(feedbackList: _feedbackList),
            ),
          ],
        ),
      ),
    );
  }

  // exercise type selector drop down choice box
  Widget _buildExerciseTypeSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Exercise Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: _selectedExerciseType ??= _dropdownItems.first,
      onChanged: (String? newValue) {
        setState(() {
          _selectedExerciseType = newValue;
        });
      },
      items: _dropdownItems.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  // video player 
  Widget _buildVideoPlayer() {
    return Container(
      height: 240,
      width: 360,
      decoration: BoxDecoration(
        color: _videoStream != null ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _videoStream != null
            ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  _videoStream!,
                  fit: BoxFit.contain,
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  // buttons for choosing removing video
  Widget _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _pickVideo,
          child: const Text('Choose Video'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _removeVideo,
          child: const Text('Remove Video'),
        ),
      ],
    );
  }

  // counting mistakes
  Widget _buildFeedbackInfo() {
    return Text(
      'Mistakes: ${_feedbackList.length}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  // feedback list widget
  Widget buildListBuilder({required List<PoseFeedbackData> feedbackList}) {
    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final feedback = feedbackList[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListItemPage(
                      image: feedback.imageBytes,
                      header: feedback.header,
                      description: feedback.description,
                    ),
                  ),
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.memory(
                  feedback.imageBytes,
                  fit: BoxFit.fill,
                ),
              ),
              title: Text(
                feedback.header,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _truncateDescription(feedback.description),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
