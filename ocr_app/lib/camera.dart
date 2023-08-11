import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  double result = 0;
  double total = 0;
  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Stack(children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the preview.
                  return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CameraPreview(_controller));
                } else {
                  // Otherwise, display a loading indicator.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.01,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Total: ${total.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 20, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: FloatingActionButton(
                // Provide an onPressed callback.
                onPressed: () async {
                  // Take the Picture in a try / catch block. If anything goes wrong,
                  // catch the error.
                  try {
                    // Ensure that the camera is initialized.
                    await _initializeControllerFuture;

                    // Attempt to take a picture and get the file `image`
                    // where it was saved.
                    final image = await _controller.takePicture();

                    if (!mounted) return;

                    // If the picture was taken, display it on a new screen.
                    result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DisplayPictureScreen(
                          // Pass the automatically generated path to
                          // the DisplayPictureScreen widget.
                          imagePath: image.path,
                          total: total,
                        ),
                      ),
                    );
                    setState(() {
                      total += result;
                    });
                  } catch (e) {
                    // If an error occurs, log the error to the console.
                    debugPrint(e.toString());
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text('Tomar foto'),
                    ),
                  ],
                ),
              ),
            ),
          )
        ]));
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final double total;

  const DisplayPictureScreen(
      {super.key, required this.imagePath, required this.total});

  @override
  State<DisplayPictureScreen> createState() => DisplayPictureScreenState();
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String filteredText = '';
  bool dialogOpen = false;
  double sum = 0;
  List extractedNumbers = [];
  List extractedText = [];

  void _calculateSum() {
    for (int i = 0; i < extractedNumbers.length; i++) {
      sum += double.parse(extractedNumbers[i][0].replaceAll(',', '')) *
          double.parse('${extractedNumbers[i][1].toString()}1') *
          -1;
    }

    debugPrint('Sum: $sum');

    setState(() {
      sum = sum;
    });
  }

  void _resetSum() {
    setState(() {
      sum = 0;
    });
  }

  Future<void> extractText(imagePath) async {
    extractedText.clear();
    extractedNumbers.clear();

    final inputImage = InputImage.fromFilePath(imagePath);
    final textDetector = TextRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        // recognizedText += '${line.text}\n';
        // Check if the line contains a comma and a dot
        filteredText = line.text;
        filteredText = filteredText.replaceAll(RegExp('[a-zA-Z \$]'), '');
        if (filteredText.isEmpty || filteredText.contains('-')) {
          continue;
        }
        debugPrint("Extracted: $filteredText");
        var exp = RegExp(r',');
        if (exp.allMatches(filteredText).length > 1) {
          int lastCommaIndex = filteredText.lastIndexOf(exp);
          filteredText = filteredText.replaceRange(
              lastCommaIndex, lastCommaIndex + 1, '.');
        }
        if (filteredText.contains(',') && filteredText.contains('.')) {
          // If it does, remove the comma
          filteredText = filteredText.replaceAll(',', '');
          // debugPrint("Remove comma: $filteredText");
        }
        // Check if the line contains a comma
        else if (filteredText.contains(',')) {
          // If it does, replace it with a dot
          filteredText = filteredText.replaceAll(',', '.');
          // debugPrint("Change comma for dot $filteredText");
        }

        if (double.tryParse(filteredText.replaceAll(RegExp('[^0-9.]'), '')) !=
            null) {
          extractedNumbers.add([filteredText, '-']);
          debugPrint("Total: $sum");
        }
      }
    }

    setState(() {
      dialogOpen = true;
    });

    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, sum);
        return false;
      },
      child: Scaffold(
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Stack(children: [
          // add a back button

          Column(children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: IconButton(
                icon: const Row(
                    children: [Icon(Icons.arrow_back), Text('Volver')]),
                onPressed: () {
                  Navigator.pop(context, sum);
                },
              ),
            ),
            Center(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.file(File(widget.imagePath)))),

            // add a process button
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.06),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: FloatingActionButton(
                  onPressed: () {
                    extractText(widget.imagePath);
                  },
                  child: const Text('Procesar'),
                ),
              ),
            )
          ]),
          if (dialogOpen)
            AlertDialog(
              title: Column(
                children: [
                  const Center(child: Text('Cifras extraidas')),
                  Center(
                      child: Text(
                    'Subtotal: ${sum.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, color: Colors.orange),
                  ))
                ],
              ),
              content: Scrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    children: [
                      Center(
                          child: Column(children: [
                        for (int i = 0; i < extractedNumbers.length; i++)
                          Row(children: [
                            SizedBox(
                              height: 40,
                              child: TextButton(
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          const EdgeInsets.all(0))),
                                  onPressed: () {
                                    setState(() {
                                      extractedNumbers[i][1] =
                                          extractedNumbers[i][1] == '-'
                                              ? '+'
                                              : '-';
                                    });
                                  },
                                  child: extractedNumbers[i][1] == '-'
                                      ? const Icon(Icons.remove,
                                          color: Colors.red)
                                      : const Icon(Icons.add,
                                          color: Colors.green)),
                            ),
                            Text(extractedNumbers[i][0])
                          ])
                      ])),
                      // Center(
                      //     child: Padding(
                      //   padding: const EdgeInsets.only(top: 20),
                      //   child: Text('Suma: ${sum.toStringAsFixed(2)}'),
                      // ))
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    setState(() {
                      dialogOpen = false;
                    });
                  },
                  child:
                      const Text('Cerrar', style: TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: _resetSum, child: const Text('Reset')),
                TextButton(onPressed: _calculateSum, child: const Text('Sumar'))
              ],
            )
        ]),
      ),
    );
  }
}
