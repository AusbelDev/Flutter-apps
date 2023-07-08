// import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OCRApp());
}

class OCRApp extends StatefulWidget {
  const OCRApp({super.key});

  @override
  State<OCRApp> get createState => _OCRAppState();
}

class _OCRAppState extends State<OCRApp> {
  // late File _pickedImage = File('downloads/images.png');
  List<File> _pickedImages = [];
  List<String> _recognizedTexts = [];
  int _processedImageCount = 0;
  double maxTotal = 0;

  Future<void> _pickImages() async {
    final imagePicker = ImagePicker();
    maxTotal = 0;
    _processedImageCount = 0;
    final pickedImages = await imagePicker.pickMultiImage(
        imageQuality: 100, // To set quality of images
        maxHeight: 1000, // To set maxheight of images that you want in your app
        maxWidth: 1000);
    setState(() {
      if (pickedImages.isNotEmpty) {
        _pickedImages =
            pickedImages.map((pickedImage) => File(pickedImage.path)).toList();
        _recognizedTexts = List<String>.filled(_pickedImages.length, '');
      } else {
        print('No images selected.');
      }
    });

    _processImages();
  }

  Future<void> _processImages() async {
    final textDetector = GoogleMlKit.vision.textRecognizer();

    String filteredText = '';
    for (int i = 0; i < _pickedImages.length; i++) {
      final inputImage = InputImage.fromFile(_pickedImages[i]);
      final RecognizedText recognisedText =
          await textDetector.processImage(inputImage);

      // String recognizedText = '';
      double total = 0;
      for (TextBlock block in recognisedText.blocks) {
        for (TextLine line in block.lines) {
          // recognizedText += '${line.text}\n';
          // Check if the line contains a comma and a dot
          filteredText = line.text;
          if (filteredText.contains(',') && filteredText.contains('.')) {
            // If it does, remove the comma
            filteredText = filteredText.replaceAll(',', '');
          }
          // Check if the line contains a comma
          else if (filteredText.contains(',')) {
            // If it does, replace it with a dot
            filteredText = filteredText.replaceAll(',', '.');
          }

          if (double.tryParse(filteredText.replaceAll(RegExp('[^0-9.]'), '')) !=
              null) {
            total +=
                double.parse(filteredText.replaceAll(RegExp('[^0-9.]'), ''));
          }
        }
      }
      maxTotal += total;
      _processedImageCount++;
      // debugPrint(recognizedText);

      setState(() {
        _recognizedTexts[i] = 'Total de página: ${total.toStringAsFixed(2)}';
      });
    }

    textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR App',
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('SP Scanner'),
        ),
        body: ListView.builder(
          itemCount: _pickedImages.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Image.file(
                    _pickedImages[index],
                    height: 200,
                    width: 80,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _recognizedTexts[index],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickImages,
          child: const Icon(Icons.photo_library),
        ),
        bottomNavigationBar: _pickedImages.isNotEmpty
            ? BottomAppBar(
                color: Colors.blue,
                height: 70,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _processedImageCount / _pickedImages.length,
                      backgroundColor: Colors.white,
                      // minHeight: 20,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    Expanded(
                      child: Text(
                        'Total de documento: ${maxTotal.toStringAsFixed(2)}',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Progress: ${(_processedImageCount / _pickedImages.length * 100).toStringAsFixed(1)}%',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
