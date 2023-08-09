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
  State<ScalableOCRWidget> createState() => _ScalableOCRWidgetState();
}

class _ScalableOCRWidgetState extends State<ScalableOCRWidget> {
  String text = "";
  bool add = false;
  String floatText = "";
  final StreamController<String> controller = StreamController<String>();

  void setText(value) {
    controller.add(value);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  void _addTotal() {
    setState(() {
      add = !add;
    });
    _getFloats(floatText);
  }

  double maxTotal = 0;

  void onPressed() {
    maxTotal = 0;
  }

  void _getFloats(String s) {
    double total = 0;
    String filteredText = '';
    filteredText = s.replaceAll(RegExp('[^0-9.,]'), '');
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
    if (add) {
      add = false;
      maxTotal += total;
    }
    // maxTotal += total;
    // return maxTotal;
    setState(() {
      maxTotal = maxTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        ScalableOCR(
            paintboxCustom: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0
              ..color = const Color.fromARGB(255, 255, 255, 255),
            boxLeftOff: 5,
            boxBottomOff: 8,
            boxRightOff: 5,
            boxTopOff: 30,
            boxHeight: MediaQuery.of(context).size.height / 2,
            getRawData: (value) {
              inspect(value);
            },
            getScannedText: (value) {
              setText(value);
            }),
        StreamBuilder<String>(
            stream: controller.stream,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              floatText = snapshot.data != null ? snapshot.data! : "";
              return Result(
                  text: snapshot.data != null ? snapshot.data! : "",
                  total: maxTotal);
            }),
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: ElevatedButton(
            onPressed: _addTotal,
            child: const Text("Sumar al total"),
          ),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class Result extends StatefulWidget {
  Result({
    Key? key,
    required this.text,
    required this.total,
  }) : super(key: key);
  double total = 0;

  final String text;

  // @override
  // Widget build(BuildContext context) {
  //   return Text("Readed text: ${_getFloats(text)}");
  // }

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
              "Cifra detectada: ${widget.text.replaceAll(RegExp('[^0-9.]'), '')}"),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.3, right: 20),
                child: Text("Total actual: ${widget.total}"),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: FilledButton(
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(0)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red)),
                    onPressed: _ScalableOCRWidgetState().onPressed,
                    child: const Icon(Icons.restart_alt)),
              )
            ],
          ),
        ),
      ],
    );
  }
}
