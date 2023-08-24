import 'dart:ffi';
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
        home: MyHomePage(camera: widget.camera));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.camera}) : super(key: key);
  final CameraDescription camera;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool foreignCurrency = false;
  int tabIndex = 1;
  Type type = Float;
  bool isNumeric = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
            centerTitle: true,
            title: Text('Ez SP',
                style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade300)),
            // backgroundColor: const Color.fromRGBO(26, 93, 26, 1),
            leading: tabIndex != 0
                ? null
                : PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: const Center(
                                    child: Text('Extraer datos numericos')),
                                backgroundColor: Colors.blue.shade300,
                              ));
                              setState(() {
                                type = Float;
                                isNumeric = true;
                              });
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                    value: isNumeric,
                                    onChanged: (value) {
                                      setState(() {
                                        isNumeric = isNumeric;
                                      });
                                    }),
                                const Text("Datos Numericos"),
                              ],
                            )),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: const Center(
                                    child: Text('Extraer datos de texto')),
                                backgroundColor: Colors.blue.shade300,
                              ));
                              setState(() {
                                type = String;
                                isNumeric = false;
                              });
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: !isNumeric,
                                  onChanged: null,
                                ),
                                const Text("Datos de Texto"),
                              ],
                            )),
                      )
                    ],
                    onSelected: (value) {
                      debugPrint("You selected $value");
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
            actions: [
              type == Float
                  ? IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: foreignCurrency
                              ? const Center(child: Text('Moneda Nacional'))
                              : const Center(child: Text('Moneda Extranjera')),
                          backgroundColor: Colors.blue.shade300,
                        ));
                        setState(() {
                          foreignCurrency = !foreignCurrency;
                        });
                        debugPrint(foreignCurrency.toString());
                      },
                      icon: Icon(Icons.monetization_on_outlined,
                          color: foreignCurrency
                              ? const Color.fromRGBO(0, 255, 0, 1)
                              : const Color.fromRGBO(255, 0, 0, 1)))
                  : Container(),
            ],
            bottom: TabBar(
              onTap: (value) {
                if (type == String && value != 0) {
                  type = Float;
                  isNumeric = true;
                }

                setState(() {
                  tabIndex = value;
                  type = type;
                  isNumeric = isNumeric;
                });
              },
              tabs: const <Widget>[
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
            TakePictureScreen(
              camera: widget.camera,
              foreignCurrency: foreignCurrency,
              dataType: type,
            ),
            ImageExtractor(foreignCurrency: foreignCurrency),
            PdfBoxSelector(foreignCurrency: foreignCurrency)
          ],
        ),
      ),
    );
  }
}
