import 'dart:typed_data';

import 'package:flutter/material.dart';

// page for pose feedback information
class ListItemPage extends StatelessWidget {
  final Uint8List image;
  final String header;
  final String description;

  const ListItemPage({
    super.key,
    required this.image,
    required this.header,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(header),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.memory(
                image,
                height: 300,
                fit: BoxFit.contain,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
