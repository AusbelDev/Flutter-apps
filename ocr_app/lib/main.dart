// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'view_pdf.dart';
import 'camera.dart';
import 'images.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;
  runApp(OCRApp(
    camera: firstCamera,
  ));
}

class OCRApp extends StatefulWidget {
  const OCRApp({super.key, required this.camera});
  final CameraDescription camera;
  @override
  State<OCRApp> createState() => _OCRAppState();
}

class _OCRAppState extends State<OCRApp> {
  // late File _pickedImage = File('downloads/images.png');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ez SP',
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
                title: Text('Ez SP',
                    style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: const ColorScheme.dark().secondary)),
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
                TakePictureScreen(camera: widget.camera),
                const ImageExtractor(),
                const PdfBoxSelector()
              ],
            ),
          ),
        ));
  }
}
