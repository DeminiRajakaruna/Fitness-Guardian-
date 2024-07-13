import 'dart:typed_data';
// class for posture analysis feedback recieved
class PoseFeedbackData {
  Uint8List imageBytes;
  final String header;
  final String description;

  PoseFeedbackData({
    required this.imageBytes,
    required this.header,
    required this.description,
  });
}
