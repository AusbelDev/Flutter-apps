import 'dart:io';

// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class PdfBoxSelector extends StatefulWidget {
  const PdfBoxSelector({super.key});

  @override
  State<PdfBoxSelector> createState() => _PdfBoxSelectorState();
}

class _PdfBoxSelectorState extends State<PdfBoxSelector> {
  // final GlobalKey _pdfKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  // Coordinates of the box to be drawn
  double _startX = 0;
  double _startY = 0;
  double _endX = 0;
  double _endY = 0;
  double pdfPageWidth = 0;
  double pdfPageHeight = 0;
  double containerHeight = 1;
  double containerWidth = 1;
  double pdfScale = 1.0;
  String pdfFile = '';
  double boxStartX = 0;
  double boxStartY = 0;
  double boxEndX = 0;
  double boxEndY = 0;
  double pdfOffsetX = 0;
  double pdfOffsetY = 0;
  bool isDragging = false;
  List extractedText = [];
  List extractedNumbers = [];
  double scaledContainerHeight = 1;
  double sum = 0;
  bool dialog = false;
  double viewOffset = 0;

  void selectPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      pdfFile = result.files.single.path!;
      setState(() {
        pdfFile = pdfFile;
      });
    }
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _startX = details.localPosition.dx;
      _startY = details.localPosition.dy;
      _endX = details.localPosition.dx;
      _endY = details.localPosition.dy;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _endX = details.localPosition.dx;
      _endY = details.localPosition.dy;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      isDragging = true;
    });
  }

  void _convertBoxCoordinatesToPdfCoordinates() {
    pdfOffsetX = _pdfViewerController.scrollOffset.dx;
    pdfOffsetY = _pdfViewerController.scrollOffset.dy;
    viewOffset = containerWidth * (_pdfViewerController.pageNumber - 1) -
        4 * (_pdfViewerController.pageNumber - 1);
    debugPrint('viewOffset: $viewOffset');
    debugPrint('pdfPageWidth: $pdfPageWidth, pdfPageHeight: $pdfPageHeight');
    debugPrint('pdfOffsetX: $pdfOffsetX, pdfOffsetY: $pdfOffsetY');
    debugPrint(
        'containerWidth: $containerWidth, containerHeight: $containerHeight');
    // Get the current zoom level of the PDF viewer
    double zoomLevel = _pdfViewerController.zoomLevel;
    debugPrint('zoomLevel: $zoomLevel');
    // Convert box coordinates to pdf coordinates
    double pdfRatio = pdfPageWidth / pdfPageHeight;
    scaledContainerHeight = containerWidth / pdfRatio;

    double pdfStartX = (_startX * pdfPageWidth / containerWidth);
    double pdfStartY =
        ((_startY - (containerHeight - scaledContainerHeight) / 2) *
            pdfPageHeight /
            scaledContainerHeight);
    double pdfEndX = (_endX * pdfPageWidth / containerWidth);
    double pdfEndY = ((_endY - (containerHeight - scaledContainerHeight) / 2) *
        pdfPageHeight /
        scaledContainerHeight);

    if (zoomLevel != 1.0) {
      pdfStartX = pdfOffsetX * (pdfPageWidth / containerWidth) +
          (_startX * (pdfPageWidth / containerWidth) / zoomLevel) -
          viewOffset * (pdfPageWidth / containerWidth);

      pdfStartY = pdfOffsetY * (pdfPageHeight / scaledContainerHeight) +
          (_startY) * (pdfPageHeight / scaledContainerHeight) / zoomLevel;

      pdfEndX = pdfOffsetX * (pdfPageWidth / containerWidth) +
          (_endX * (pdfPageWidth / containerWidth) / zoomLevel) -
          viewOffset * (pdfPageWidth / containerWidth);

      pdfEndY = pdfOffsetY * (pdfPageHeight / scaledContainerHeight) +
          (_endY) * (pdfPageHeight / scaledContainerHeight) / zoomLevel;
    }

    // Set the box coordinates
    setState(() {
      boxStartX = pdfStartX;
      boxStartY = pdfStartY;
      boxEndX = pdfEndX;
      boxEndY = pdfEndY;
    });
  }

  String _extractNumbers(String text) {
    debugPrint('Text: $text');
    var number = '';
    RegExp regExp = RegExp(r'\d*,?\d+\.\d+');
    number = regExp.stringMatch(text) ?? '';
    return number;
  }

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

  Future<List<int>> _readDocumentData(String name) async {
    final file = File(name);
    // final ByteData data = await rootBundle.load(name);
    final data = await file.readAsBytes();

    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _textExtraction() async {
    extractedText.clear();
    extractedNumbers.clear();
    var currentPage = _pdfViewerController.pageNumber;
    isDragging = false;
    //Load the PDF document.
    final PdfDocument document =
        PdfDocument(inputBytes: await _readDocumentData(pdfFile));

    pdfPageHeight = document.pages[currentPage - 1].size.height;
    pdfPageWidth = document.pages[currentPage - 1].size.width;

    _convertBoxCoordinatesToPdfCoordinates();

    final PdfTextExtractor extractor = PdfTextExtractor(document);

    List<TextLine> result =
        extractor.extractTextLines(startPageIndex: currentPage - 1);

    Rect textBounds = Rect.fromLTWH(
        (boxStartX), (boxStartY), (boxEndX - boxStartX), (boxEndY - boxStartY));
    debugPrint('textBounds: $textBounds');

    //Save and launch the file.
    for (int i = 0; i < result.length; i++) {
      List<TextWord> wordCollection = result[i].wordCollection;
      for (int j = 0; j < wordCollection.length; j++) {
        if (textBounds.overlaps(wordCollection[j].bounds)) {
          String number = _extractNumbers(wordCollection[j].text);
          extractedText.add(number);
        }
      }
    }
    debugPrint('currentPage: $currentPage');
    document.pages[currentPage - 1].annotations.add(PdfRectangleAnnotation(
        textBounds, 'Rectangle',
        color: PdfColor(255, 0, 0), setAppearance: true));

//Save the document.
    final directory = await getApplicationDocumentsDirectory();

    final localPath = directory.path;
    final path = localPath;

    File('$path/annotations.pdf').writeAsBytes(await document.save());

    document.dispose();

    for (int i = 0; i < extractedText.length; i++) {
      debugPrint('extractedText: ${extractedText[i]}');
      if (extractedText[i] != '') {
        extractedNumbers.add([extractedText[i], '-']);
      }
    }

    // _showDialog(extractedNumbers.join('\n'));
    setState(() {
      dialog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          pdfFile == ''
              ? const Center(child: Text('No hay archivo seleccionado'))
              : GestureDetector(
                  onPanStart: isDragging ? _handlePanStart : (details) => {},
                  onPanUpdate: isDragging ? _handlePanUpdate : (details) => {},
                  onPanEnd: isDragging ? _handlePanEnd : (details) => {},
                  child: SizedBox(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints box) {
                        containerWidth = box.maxWidth;
                        containerHeight = box.maxHeight;

                        return SfPdfViewer.file(
                          File(pdfFile),
                          controller: _pdfViewerController,
                          pageLayoutMode: PdfPageLayoutMode.continuous,
                          scrollDirection: PdfScrollDirection.horizontal,
                          onPageChanged: (details) {},
                        );
                      },
                    ),
                  )),
          // SfPdfViewer.file(File(pdfFile))))),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            child: FloatingActionButton(
              onPressed: selectPdfFile,
              child: const Icon(Icons.add),
            ),
          ),
          if (pdfFile != '')
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.05,
              left: MediaQuery.of(context).size.width * 0.05,
              child: FloatingActionButton(
                onPressed: dialog
                    ? null
                    : () {
                        setState(() {
                          isDragging = !isDragging;
                        });
                      },
                child: const Icon(Icons.draw_outlined),
              ),
            ),
          if (isDragging)
            Positioned(
              left: _startX,
              top: _startY,
              width: _endX - _startX,
              height: _endY - _startY,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 1.0),
                ),
              ),
            ),
          if (isDragging)
            Positioned(
                left: MediaQuery.of(context).size.width / 2 - 30,
                bottom: MediaQuery.of(context).size.height * 0.05,
                child: ElevatedButton(
                    onPressed: _textExtraction,
                    style: ButtonStyle(
                      padding:
                          MaterialStateProperty.all(const EdgeInsets.all(0)),
                      backgroundColor: MaterialStateProperty.all(Colors.red),
                    ),
                    child: const Icon(
                      Icons.save_alt,
                      color: Colors.white,
                    ))),
          if (dialog)
            AlertDialog(
              title: Column(
                children: [
                  const Center(child: Text('Cifras extraidas')),
                  Center(
                      child: Text(
                    'Total: ${sum.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, color: Colors.green),
                  )),
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
                      isDragging = false;
                      dialog = false;
                    });
                  },
                  child:
                      const Text('Cerrar', style: TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: _resetSum, child: const Text('Reset')),
                TextButton(onPressed: _calculateSum, child: const Text('Sumar'))
              ],
            )
        ],
      ),
    );
  }
}
