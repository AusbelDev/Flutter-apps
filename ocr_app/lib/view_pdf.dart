import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';

class PdfBoxSelector extends StatefulWidget {
  const PdfBoxSelector({super.key});

  @override
  State<PdfBoxSelector> get createState => _PdfBoxSelectorState();
}

class _PdfBoxSelectorState extends State<PdfBoxSelector> {
  // final GlobalKey _pdfKey = GlobalKey();

  // Coordinates of the box to be drawn
  double _startX = 0;
  double _startY = 0;
  double _endX = 0;
  double _endY = 0;
  double pdfPageWidth = 0;
  double pdfPageHeight = 0;
  double containerHeight = 0;
  double containerWidth = 0;
  double pdfScale = 1.0;
  String pdfFile = '';
  double boxStartX = 0;
  double boxStartY = 0;
  double boxEndX = 0;
  double boxEndY = 0;
  bool isDragging = false;
  List extractedText = [];

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

  void _convertBoxCoordinatesToPdfCoordinates() {
    // Convert box coordinates to pdf coordinates
    double pdfRatio = pdfPageWidth / pdfPageHeight;
    double scaledContainerHeight = containerWidth / pdfRatio;
    double pdfStartX = _startX * pdfPageWidth / containerWidth;
    double pdfStartY =
        (_startY - (containerHeight - scaledContainerHeight) / 2) *
            pdfPageHeight /
            scaledContainerHeight;
    double pdfEndX = _endX * pdfPageWidth / containerWidth;
    double pdfEndY = (_endY - (containerHeight - scaledContainerHeight) / 2) *
        pdfPageHeight /
        scaledContainerHeight;

    // Swap coordinates if box is drawn from right to left or bottom to top
    if (pdfStartX > pdfEndX) {
      double temp = pdfStartX;
      pdfStartX = pdfEndX;
      pdfEndX = temp;
    }
    if (pdfStartY > pdfEndY) {
      double temp = pdfStartY;
      pdfStartY = pdfEndY;
      pdfEndY = temp;
    }

    // Set the box coordinates
    setState(() {
      boxStartX = pdfStartX;
      boxStartY = pdfStartY;
      boxEndX = pdfEndX;
      boxEndY = pdfEndY;
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
    //Load the PDF document.
    final PdfDocument document =
        PdfDocument(inputBytes: await _readDocumentData(pdfFile));

    pdfPageHeight = document.pages[0].size.height;
    pdfPageWidth = document.pages[0].size.width;

    _convertBoxCoordinatesToPdfCoordinates();

    debugPrint('pdfPageHeight: $pdfPageHeight, pdfPageWidth: $pdfPageWidth');

    final PdfTextExtractor extractor = PdfTextExtractor(document);

    List<TextLine> result = extractor.extractTextLines(startPageIndex: 0);

    Rect textBounds = Rect.fromLTWH(
        boxStartX, boxStartY, boxEndX - boxStartX, boxEndY - boxStartY);
    //Save and launch the file.
    // File('assets/output.txt').writeAsStringSync(text);
    for (int i = 0; i < result.length; i++) {
      List<TextWord> wordCollection = result[i].wordCollection;
      // debugPrint('wordCollection: $wordCollection');
      for (int j = 0; j < wordCollection.length; j++) {
        if (textBounds.overlaps(wordCollection[j].bounds)) {
          extractedText.add(wordCollection[j].text);
        }
      }
    }
    document.dispose();

    for (int i = 0; i < extractedText.length; i++) {
      debugPrint('extractedText: ${extractedText[i]}');
    }

    _showDialog(extractedText.join(' '));
  }

  void _showDialog(String text) {
    showDialog<Widget>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Extracted text'),
            content: Scrollbar(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: Text(text),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          pdfFile == ''
              ? const Center(child: Text('No file selected.'))
              : GestureDetector(
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  child: Container(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints box) {
                        containerWidth = box.maxWidth;
                        containerHeight = box.maxHeight;
                        debugPrint(
                            'width: $containerWidth, height: $containerHeight');
                        return SfPdfViewer.file(File(pdfFile),
                            onZoomLevelChanged: (details) => {
                                  pdfScale = details.newZoomLevel,
                                  debugPrint('pdfScale: $pdfScale')
                                });
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
                onPressed: () {
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
                  border: Border.all(color: Colors.red, width: 2.0),
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
                    )))
        ],
      ),
    );
  }
}
