import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageExtractor extends StatefulWidget {
  const ImageExtractor({Key? key}) : super(key: key);
  @override
  State<ImageExtractor> createState() => _ImageExtractorState();
}

class _ImageExtractorState extends State<ImageExtractor> {
  List<File> _pickedImages = [];
  List<String> _recognizedTexts = [];
  List<List<List>> pagesText = [];
  List<List<String>> pageText = [];
  List<List<List>> compareTo = [];
  List<double> pagesTotals = [];
  int _processedImageCount = 0;
  double maxTotal = 0;
  double discount = 0;
  double docTotal = 0;
  List<List<String>> result = [];

  // var maskFormatterThousands = MaskTextInputFormatter(
  //     mask: '###,###.##', filter: {"#": RegExp(r'[0-9]')});

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
        debugPrint('No has seleccionado ninguna imagen');
      }
    });

    _processImages();
  }

  Future<void> _processImages() async {
    final textDetector = TextRecognizer();
    pageText = [];
    pagesText = [];
    pagesTotals = [];
    String filteredText = '';
    for (int i = 0; i < _pickedImages.length; i++) {
      pageText = [];

      final inputImage = InputImage.fromFile(_pickedImages[i]);
      final RecognizedText recognisedText =
          await textDetector.processImage(inputImage);

      // String recognizedText = '';
      double total = 0;
      // debugPrint(discount.toString());
      for (TextBlock block in recognisedText.blocks) {
        for (TextLine line in block.lines) {
          // recognizedText += '${line.text}\n';
          // Check if the line contains a comma and a dot
          filteredText = line.text;
          filteredText = filteredText.replaceAll(RegExp('[a-zA-Z \$ |]'), '');
          if (filteredText.isEmpty) {
            continue;
          }
          // debugPrint("Extracted: $filteredText");
          var exp = RegExp(r',');
          if (exp.allMatches(filteredText).length > 1) {
            int lastCommaIndex = filteredText.lastIndexOf(exp);
            // debugPrint("Last comma index: $lastCommaIndex");
            // debugPrint("Length: ${filteredText.length}");
            if (filteredText.length - 1 - lastCommaIndex == 2) {
              filteredText = filteredText.replaceRange(
                  lastCommaIndex, lastCommaIndex + 1, '.');
              // debugPrint("Change comma for dot $filteredText");
            }
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
            pageText.add([filteredText, '-']);
            total +=
                double.parse(filteredText.replaceAll(RegExp('[^0-9.]'), ''));
            // debugPrint("Total: $total");
          }
        }
      }
      pagesTotals.add(total);
      maxTotal += total;
      _processedImageCount++;
      pagesText.add(pageText);

      setState(() {
        _recognizedTexts[i] = 'Subtotal: \$${total.toStringAsFixed(2)}';
        pagesText = pagesText;
        compareTo = pagesText;
      });
    }

    textDetector.close();
  }

  List<String> _makeNewSum(pageData) {
    double newTotal = 0;
    double minusTotal = 0;
    for (int i = 0; i < pageData.length; i++) {
      newTotal +=
          double.parse(pageData[i][0].replaceAll(RegExp('[^0-9.]'), ''));
      if (pageData[i][1] == '+') {
        minusTotal -=
            double.parse(pageData[i][0].replaceAll(RegExp('[^0-9.]'), ''));
      }
    }
    newTotal = newTotal + minusTotal;
    return ['Subtotal: \$${newTotal.toStringAsFixed(2)}', newTotal.toString()];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _pickedImages.isEmpty
            ? const Center(child: Text('No has seleccionado ninguna imagen'))
            : ListView.builder(
                itemCount: _pickedImages.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.file(
                          _pickedImages[index],
                          height: 200,
                          width: 80,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: Text(
                              _recognizedTexts[index],
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () async {
                              result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ImagePage(pagesText[index])));

                              List<String> newPageTotal = _makeNewSum(result);

                              setState(() {
                                pagesText[index] = result;
                                _recognizedTexts[index] = newPageTotal[0];
                                pagesTotals[index] =
                                    double.parse(newPageTotal[1]);
                                maxTotal = pagesTotals.sum;
                              });
                            },
                            icon: const Icon(Icons.more_vert))
                      ],
                    ),
                  );
                },
              ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.11,
          left: MediaQuery.of(context).size.width * 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: FloatingActionButton(
                  // backgroundColor: const Color.fromRGBO(26, 93, 26, 1),
                  onPressed: _pickImages,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library),
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text('Seleccionar imágenes'),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_pickedImages.isNotEmpty)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.02,
            left: MediaQuery.of(context).size.width * 0.05,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blueGrey.withOpacity(0.6),
              ),
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.08,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: LinearProgressIndicator(
                        value: _processedImageCount / _pickedImages.length,
                        backgroundColor: Colors.blueGrey,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Center(
                        child: Text(
                          'Total: \$${maxTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            backgroundColor: Colors.transparent,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Center(
                        child: Text(
                          'Progreso: ${(_processedImageCount / _pickedImages.length * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.orange),
                        ),
                      ),
                    )
                  ]),
            ),
          ),
      ],
    );
  }
}

class ImagePage extends StatefulWidget {
  final List<List> pageText;
  const ImagePage(this.pageText, {super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  List<List> pageTextDetail = [];
  @override
  void initState() {
    pageTextDetail = widget.pageText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, pageTextDetail);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalles'),
        ),
        body: ListView.builder(
          itemCount: pageTextDetail.length,
          itemBuilder: (BuildContext context, int index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: TextButton(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(0))),
                      onPressed: () {
                        setState(() {
                          pageTextDetail[index][1] =
                              pageTextDetail[index][1] == '-' ? '+' : '-';
                        });
                      },
                      child: pageTextDetail[index][1] == '-'
                          ? const Icon(Icons.remove, color: Colors.red)
                          : const Icon(Icons.add, color: Colors.green)),
                ),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Center(child: Text('${pageTextDetail[index][0]}'))),
              ],
            );
          },
        ),
      ),
    );
  }
}
