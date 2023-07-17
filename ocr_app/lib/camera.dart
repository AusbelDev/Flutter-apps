import 'dart:async';
// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'dart:developer';
// import 'package:camera/camera.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';

class ScalableOCRWidget extends StatefulWidget {
  const ScalableOCRWidget({super.key});

  // final String title;

  @override
  State<ScalableOCRWidget> get createState => _ScalableOCRWidgetState();
}

class _ScalableOCRWidgetState extends State<ScalableOCRWidget> {
  String text = "";
  final StreamController<String> controller = StreamController<String>();

  void setText(value) {
    controller.add(value);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        ScalableOCR(
            paintboxCustom: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0
              ..color = const Color.fromARGB(153, 102, 160, 241),
            boxLeftOff: 5,
            boxBottomOff: 2.5,
            boxRightOff: 5,
            boxTopOff: 2.5,
            boxHeight: MediaQuery.of(context).size.height / 3,
            getRawData: (value) {
              inspect(value);
            },
            getScannedText: (value) {
              setText(value);
            }),
        StreamBuilder<String>(
          stream: controller.stream,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            return Result(text: snapshot.data != null ? snapshot.data! : "");
          },
        )
      ],
    );
  }
}

class Result extends StatefulWidget {
  Result({
    Key? key,
    required this.text,
  }) : super(key: key);
  double total = 0;

  final String text;

  // @override
  // Widget build(BuildContext context) {
  //   return Text("Readed text: ${_getFloats(text)}");
  // }

  @override
  State<Result> get createState => _ResultState();
}

class _ResultState extends State<Result> {
  double maxTotal = 0;

  double _getFloats(String s) {
    double total = 0;
    String filteredText = '';
    filteredText = s;
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
      total += double.parse(filteredText.replaceAll(RegExp('[^0-9.]'), ''));
    }

    maxTotal += total;
    return maxTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Text("Readed text: ${_getFloats(widget.text)}");
  }
}
