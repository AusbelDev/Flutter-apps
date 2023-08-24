import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';

class Excel {
  String excelFile = '';

  Future<File> _selectExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null) {
      excelFile = result.files.single.path!;
      return File(excelFile);
    }

    throw Exception('No file selected');
  }

  Future<ex.Excel> _loadExcel() async {
    final file = await _selectExcelFile();
    final bytes = await file.readAsBytes();
    final excel = ex.Excel.decodeBytes(bytes);
    return excel;
  }

  Future<List<String>> getSheetNames() async {
    final excel = await _loadExcel();
    return excel.tables.keys.toList();
  }

  Future<List<List>> getSheetData() async {
    final excel = await _loadExcel();
    final sheetName = excel.tables.keys.toList()[0];
    final sheet = excel.tables[sheetName];
    final data = sheet!.rows;
    final List<List> result = [];
    List<String> cellValues = [];
    for (final row in data) {
      for (final cell in row) {
        if (cell == null) continue;
        cellValues.add(cell.value.toString());
      }
      result.add(cellValues);
      cellValues = [];
    }
    return result;
  }
}
