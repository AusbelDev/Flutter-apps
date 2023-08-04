// import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'view_pdf.dart';
import 'camera.dart';

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
  double discount = 0;
  double docTotal = 0;
  bool appliedDiscount = false;
  bool discountInput = false;
  bool totalInput = false;

  // var maskFormatterThousands = MaskTextInputFormatter(
  //     mask: '###,###.##', filter: {"#": RegExp(r'[0-9]')});

  void toogleDiscount() {
    setState(() {
      discountInput = !discountInput;
    });
  }

  void toogleTotal() {
    setState(() {
      totalInput = !totalInput;
    });
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: !discountInput
              ? const Text("Agregar descuento")
              : const Text("Quitar descuento"),
        ),
        PopupMenuItem(
          value: 2,
          child: !totalInput
              ? const Text("Agregar total")
              : const Text("Quitar total"),
        ),
      ],
      onSelected: (value) {
        if (value == 1) {
          toogleDiscount();
        } else if (value == 2) {
          toogleTotal();
        }
      },
    );
  }

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
        debugPrint('No images selected.');
      }
    });

    _processImages();
  }

  Future<void> _processImages() async {
    final textDetector = TextRecognizer();

    String filteredText = '';
    for (int i = 0; i < _pickedImages.length; i++) {
      final inputImage = InputImage.fromFile(_pickedImages[i]);
      final RecognizedText recognisedText =
          await textDetector.processImage(inputImage);

      // String recognizedText = '';
      appliedDiscount = false;
      double total = 0;
      debugPrint(discount.toString());
      for (TextBlock block in recognisedText.blocks) {
        for (TextLine line in block.lines) {
          // recognizedText += '${line.text}\n';
          // Check if the line contains a comma and a dot
          filteredText = line.text;
          filteredText = filteredText.replaceAll(RegExp('[a-zA-Z \$]'), '');
          debugPrint("Extracted: $filteredText");
          if (filteredText.contains(',') && filteredText.contains('.')) {
            // If it does, remove the comma
            filteredText = filteredText.replaceAll(',', '');
            debugPrint("Remove comma: $filteredText");
          }
          // Check if the line contains a comma
          else if (filteredText.contains(',')) {
            // If it does, replace it with a dot
            filteredText = filteredText.replaceAll(',', '.');
            debugPrint("Change comma for dot $filteredText");
          }

          if (double.tryParse(filteredText.replaceAll(RegExp('[^0-9.]'), '')) !=
              null) {
            if (double.parse(filteredText) == discount && !appliedDiscount) {
              debugPrint("Discount: $discount");
              total -= discount;
              appliedDiscount = true;
            } else {
              total +=
                  double.parse(filteredText.replaceAll(RegExp('[^0-9.]'), ''));
              debugPrint("Total: $total");
            }
          }
        }
      }
      maxTotal += total;
      _processedImageCount++;

      setState(() {
        _recognizedTexts[i] = !appliedDiscount
            ? 'Total de página: \$${total.toStringAsFixed(2)}'
            : 'Total de página + descuento: \$${total.toStringAsFixed(2)}';
      });
    }
    if (docTotal != maxTotal && appliedDiscount == false) {
      maxTotal -= discount;
      appliedDiscount = true;
    }

    textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SP Scanner',
        theme: ThemeData(
          colorSchemeSeed: Colors.blueGrey,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.blueGrey,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: DefaultTabController(
          initialIndex: 1,
          length: 3,
          child: Scaffold(
            extendBody: true,
            // backgroundColor: const Color.fromRGBO(241, 201, 59, 1),
            appBar: AppBar(
                centerTitle: true,
                title: const Text('SP Scanner'),
                // backgroundColor: const Color.fromRGBO(26, 93, 26, 1),
                bottom: const TabBar(
                  tabs: <Widget>[
                    Tab(
                      icon: Icon(Icons.camera_alt),
                      text: 'Camara',
                    ),
                    Tab(
                      icon: Icon(Icons.photo_library),
                      text: 'Galeria',
                    ),
                    Tab(
                      icon: Icon(Icons.document_scanner),
                      text: 'Analizar PDF',
                    ),
                  ],
                )),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const ScalableOCRWidget(),
                Column(
                  children: [
                    if (discountInput)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                top: 20,
                                bottom: 10,
                                left: MediaQuery.of(context).size.width / 8),
                            child: SizedBox(
                              width: 250,
                              height: 50,
                              child: TextField(
                                // obscureText: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Descuento'),
                                controller: discount == 0
                                    ? null
                                    : TextEditingController(
                                        text: discount.toString()),
                                onChanged: (value) {
                                  if (double.tryParse(value) != null) {
                                    discount = double.parse(value);
                                  }
                                },
                                // inputFormatters: [maskFormatterThousands],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 15),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: FilledButton.tonal(
                                  onPressed: toogleDiscount,
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        const EdgeInsets.all(0)),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.red),
                                    // iconSize: MaterialStateProperty.all(30),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20.0))),
                                    fixedSize: MaterialStateProperty.all<Size>(
                                        const Size(20, 20)),
                                  ),
                                  child: const Icon(Icons.remove)),
                            ),
                          )
                        ],
                      ),
                    if (totalInput)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                top: 8,
                                bottom: 20,
                                left: MediaQuery.of(context).size.width / 8),
                            child: SizedBox(
                              width: 250,
                              height: 50,
                              child: TextField(
                                // obscureText: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Total'),
                                controller: docTotal == 0
                                    ? null
                                    : TextEditingController(
                                        text: docTotal.toString()),
                                onChanged: (value) {
                                  if (double.tryParse(value) != null) {
                                    docTotal = double.parse(value);
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 15, bottom: 10),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: FilledButton.tonal(
                                  onPressed: toogleTotal,
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                        const EdgeInsets.all(0)),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.red),
                                    // iconSize: MaterialStateProperty.all(30),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20.0))),
                                    fixedSize: MaterialStateProperty.all<Size>(
                                        const Size(20, 20)),
                                  ),
                                  child: const Icon(Icons.remove)),
                            ),
                          )
                        ],
                      ),
                    _pickedImages.isEmpty
                        ? const Expanded(
                            child: Center(child: Text('No images selected.')))
                        : Expanded(
                            child: ListView.builder(
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
                                        child: Center(
                                          child: Text(
                                            _recognizedTexts[index],
                                            style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.blueGrey),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: 20,
                              left: MediaQuery.of(context).size.width * 0.05,
                              right: 50),
                          child: Align(
                            alignment: const Alignment(-0.9, 0.5),
                            child: FloatingActionButton(
                              // backgroundColor: const Color.fromRGBO(26, 93, 26, 1),
                              onPressed: _buildPopupMenu,
                              child: _buildPopupMenu(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: 20,
                              left: MediaQuery.of(context).size.width * 0.5),
                          child: Align(
                            alignment: const Alignment(0.9, 0.5),
                            child: FloatingActionButton(
                              // backgroundColor: const Color.fromRGBO(26, 93, 26, 1),
                              onPressed: _pickImages,
                              child: const Icon(Icons.photo_library),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pickedImages.isNotEmpty)
                      BottomAppBar(
                        // color: const Color.fromRGBO(26, 93, 26, 1),
                        color: Colors.transparent,
                        elevation: 0,
                        height: 100,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _processedImageCount /
                                      _pickedImages.length,
                                  backgroundColor: Colors.white,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.blueAccent),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total de documento: \$${maxTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Progreso: ${(_processedImageCount / _pickedImages.length * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // const TextExtractionPdf(),
                // const PDFView(filePath: 'assets/2.pdf')
                // const MyPdfViewer()
                // Scaffold(body: SfPdfViewer.asset('assets/2.pdf'))
                const PdfBoxSelector()
              ],
            ),
          ),
        ));
  }
}
