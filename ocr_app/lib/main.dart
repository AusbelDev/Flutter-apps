import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const OCRApp());

class OCRApp extends StatefulWidget {
  const OCRApp({super.key});

  @override
  _OCRAppState createState() => _OCRAppState();
}

class _OCRAppState extends State<OCRApp> {
  late File _pickedImage;
  String _recognizedText = '';

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _pickedImage = File(pickedImage.path);
        _recognizedText = '';
      } else {
        print('No image selected.');
      }
    });

    _processImage();
  }

  Future<void> _processImage() async {
    final inputImage = InputImage.fromFile(_pickedImage);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);

    String recognizedText = '';
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        recognizedText += '${line.text}\n';
      }
    }

    setState(() {
      _recognizedText = recognizedText;
    });

    textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OCR App'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            if (_pickedImage != null)
              Image.file(
                _pickedImage,
                height: 200,
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
