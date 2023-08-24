import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'excel.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen(
      {super.key,
      required this.camera,
      required this.foreignCurrency,
      required this.dataType});

  final CameraDescription camera;
  final bool foreignCurrency;
  final Type dataType;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  double result = 0;
  double total = 0;
  double zoom = 1;
  double maxZoom = 1;
  double minZoom = 1;
  bool isCameraReady = false;
  bool showFocusCircle = false;
  double x = 0;
  double y = 0;
  List excelData = [];

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
      _controller?.getMaxZoomLevel().then((value) => maxZoom = value);
      _controller?.getMinZoomLevel().then((value) => minZoom = value);
      _controller?.setFocusMode(FocusMode.locked);
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
    }
    // Update the Boolean
    if (mounted) {
      setState(() {
        isCameraReady = _controller!.value.isInitialized;
      });
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (_controller!.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * _controller!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);
      debugPrint("point : $point");

      // Manually focus
      await _controller?.setFocusPoint(point);

      // Manually set light exposure

      setState(() {
        Future.delayed(const Duration(seconds: 2)).whenComplete(() {
          setState(() {
            showFocusCircle = false;
          });
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    onNewCameraSelected(widget.camera);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: Stack(alignment: Alignment.center, children: <Widget>[
      Stack(children: [
        isCameraReady
            ? GestureDetector(
                onTapUp: (details) {
                  _onTap(details);
                },
                child: AspectRatio(
                  aspectRatio: 1 / _controller!.value.aspectRatio,
                  child: _controller!.buildPreview(),
                ),
              )
            : Container(),
        widget.dataType == Float
            ? Positioned(
                top: MediaQuery.of(context).size.height * 0.01,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: null,
                        child: Text('Total: ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 20, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              )
            : Positioned(
                top: MediaQuery.of(context).size.height * 0.01,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          var sheetData = await Excel().getSheetData();
                          setState(() {
                            excelData = sheetData;
                          });
                        },
                        child: const Text('Cargar Excel',
                            style: TextStyle(fontSize: 20, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
      ]),
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.2,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Slider(
            value: zoom,
            onChanged: (value) async {
              setState(() {
                zoom = value;
              });
              await _controller!.setZoomLevel(zoom);
            },
            min: minZoom,
            max: maxZoom,
            label: zoom.toString(),
          ),
        ),
      ),
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.1,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.05,
          child: FloatingActionButton(
            // Provide an onPressed callback.
            onPressed: () async {
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.

                // Attempt to take a picture and get the file `image`
                // where it was saved.
                final image = await _controller!.takePicture();

                if (!mounted) return;

                // If the picture was taken, display it on a new screen.
                result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(
                      // Pass the automatically generated path to
                      // the DisplayPictureScreen widget.
                      imagePath: image.path,
                      total: total,
                      foreignCurrency: widget.foreignCurrency,
                      excelData: excelData,
                      dataType: widget.dataType,
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
  final bool foreignCurrency;
  final List excelData;
  final Type dataType;

  const DisplayPictureScreen(
      {super.key,
      required this.imagePath,
      required this.total,
      required this.foreignCurrency,
      this.excelData = const [],
      required this.dataType});

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
  Map<String, List> rfcCurp = {};
  void _calculateSum() {
    for (int i = 0; i < extractedNumbers.length; i++) {
      sum += double.parse(extractedNumbers[i][0].replaceAll(',', '')) *
          double.parse('${extractedNumbers[i][1].toString()}1') *
          -1;
    }

    setState(() {
      sum = sum;
    });
  }

  void _resetSum() {
    setState(() {
      sum = 0;
    });
  }

  String _extractNationalCurrency(String text) {
    String filteredText = text;
    var exp = RegExp(r',');
    if (exp.allMatches(filteredText).length > 1) {
      int lastCommaIndex = filteredText.lastIndexOf(exp);
      if (filteredText.length - 1 - lastCommaIndex == 2) {
        filteredText =
            filteredText.replaceRange(lastCommaIndex, lastCommaIndex + 1, '.');
      }
    }
    if (filteredText.contains(',') && filteredText.contains('.')) {
      // If it does, remove the comma
      filteredText = filteredText.replaceAll(',', '');
    }
    // Check if the line contains a comma
    else if (filteredText.contains(',')) {
      // If it does, replace it with a dot
      filteredText = filteredText.replaceAll(',', '.');
    }
    return filteredText;
  }

  String _extractForeignCurrency(String text) {
    String filteredText = text;
    var exp = RegExp(r'\.');
    if (exp.allMatches(filteredText).length > 1) {
      int lastDotIndex = filteredText.lastIndexOf(exp);
      if (filteredText.length - 1 - lastDotIndex == 2) {
        filteredText =
            filteredText.replaceRange(lastDotIndex, lastDotIndex + 1, ',');
      }
    }
    if (filteredText.contains(',') && filteredText.contains('.')) {
      filteredText = filteredText.replaceAll('.', '');
    }
    // Check if the line contains a comma
    else if (filteredText.contains('.')) {
      // If it does, replace it with a dot
      filteredText = filteredText.replaceAll('.', ',');
    }
    return filteredText;
  }

  Future<void> extractText(imagePath) async {
    extractedText.clear();
    extractedNumbers.clear();
    rfcCurp = {};

    RegExp rfcRegex = RegExp(r'[A-Z]{4}\d{6}[A-Z0-9]{0,3}');
    RegExp curpRegex = RegExp(r'[A-Z]{4}\d{6}[A-Z0-9]{8}');

    final inputImage = InputImage.fromFilePath(imagePath);
    final textDetector = TextRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        // Check if the line contains a comma and a dot
        if (widget.dataType == Float) {
          filteredText = line.text;
          filteredText = filteredText.replaceAll(RegExp(r'[^.,\d]'), '');
          if (filteredText.isEmpty || filteredText.contains('-')) {
            continue;
          }

          if (widget.foreignCurrency) {
            filteredText = _extractForeignCurrency(filteredText);
            if (double.tryParse(
                    filteredText.replaceAll(RegExp('[^0-9,]'), '')) !=
                null) {
              extractedNumbers.add([filteredText, '-']);
            }
          } else {
            filteredText = _extractNationalCurrency(filteredText);
            if (double.tryParse(
                    filteredText.replaceAll(RegExp('[^0-9.]'), '')) !=
                null) {
              extractedNumbers.add([filteredText, '-']);
            }
          }
        }

        if (widget.dataType == String) {
          debugPrint('Line: ${line.text}');
          var row = line.text;
          var existCurp = curpRegex.hasMatch(row);
          var curp = curpRegex.stringMatch(row);
          if (curp != null) {
            row = row.replaceAll(RegExp(curp), '');
          }
          var existRfc = rfcRegex.hasMatch(row);
          var rfc = rfcRegex.stringMatch(row);
          rfcCurp = {
            'CURP': [curp, existCurp],
            'RFC': [rfc, existRfc]
          };
        }
      }
    }

    debugPrint('rfcCurp: $rfcCurp');

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

          Stack(alignment: Alignment.center, children: [
            Center(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.file(File(widget.imagePath)))),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.04,
              left: MediaQuery.of(context).size.width * 0.05,
              child: IconButton(
                icon: const Row(
                    children: [Icon(Icons.arrow_back), Text('Volver')]),
                onPressed: () {
                  Navigator.pop(context, sum);
                },
              ),
            ),

            // add a process button
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.03,
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
              title: widget.dataType == Float
                  ? Column(
                      children: [
                        const Center(child: Text('Cifras extraidas')),
                        Center(
                            child: Text(
                          'Subtotal: ${sum.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.orange),
                        ))
                      ],
                    )
                  : const Center(child: Text('Verificacion de datos')),
              content: Scrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    children: [
                      Center(
                          child: widget.dataType == Float
                              ? Column(children: [
                                  for (int i = 0;
                                      i < extractedNumbers.length;
                                      i++)
                                    Row(children: [
                                      SizedBox(
                                        child: TextButton(
                                          child: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              extractedNumbers.removeAt(i);
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40,
                                        child: TextButton(
                                            style: ButtonStyle(
                                                padding:
                                                    MaterialStateProperty.all(
                                                        const EdgeInsets.all(
                                                            0))),
                                            onPressed: () {
                                              setState(() {
                                                extractedNumbers[i][1] =
                                                    extractedNumbers[i][1] ==
                                                            '-'
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
                                ])
                              : Column(children: [
                                  for (var key in rfcCurp.keys)
                                    Row(children: [
                                      Text('$key: '),
                                      Text(rfcCurp[key]![0] ??
                                          'No encontrado en la imagen'),
                                      Text(rfcCurp[key]![1] ? ' ✅' : ' ❌')
                                    ]),
                                  for (int i = 0;
                                      i < widget.excelData.length;
                                      i++)
                                    if (rfcCurp['CURP']![1] ==
                                            widget.excelData[i].contains(
                                                rfcCurp['CURP']![0]) &&
                                        rfcCurp['RFC']![1] ==
                                            widget.excelData[i]
                                                .contains(rfcCurp['RFC']![0]) &&
                                        rfcCurp['CURP']?[0] != null &&
                                        rfcCurp['RFC']?[0] != null)
                                      const Row(children: [
                                        Text('Correcto en Excel: ✅'),
                                      ])
                                ]))
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
