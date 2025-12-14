
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});
  @override State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String lang = "uz";
  final teacherCtrl = TextEditingController();
  PlatformFile? templateFile;
  List<PlatformFile> dataFiles = [];
  String apiBase = "http://10.0.2.2:8000"; // emulator default

  String status = "—";
  bool busy = false;

  Map<String, Map<String, String>> t = {
    "uz": {
      "title":"Excel AI Assistant",
      "teacher":"Ustoz F.I.O",
      "template":"1) Shablon Excel (.xlsx)",
      "data":"2) Ma’lumotlar (1–20 ta .xlsx)",
      "pickTpl":"Shablon tanlash",
      "pickData":"Fayllarni tanlash",
      "run":"Avto to‘ldirish",
      "api":"Backend URL",
      "done":"Tayyor! Fayl saqlandi.",
      "err":"Xatolik",
    },
    "ru": {
      "title":"Excel AI Assistant",
      "teacher":"Ф.И.О учителя",
      "template":"1) Шаблон Excel (.xlsx)",
      "data":"2) Данные (1–20 файлов .xlsx)",
      "pickTpl":"Выбрать шаблон",
      "pickData":"Выбрать файлы",
      "run":"Заполнить",
      "api":"URL сервера",
      "done":"Готово! Файл сохранён.",
      "err":"Ошибка",
    },
    "en": {
      "title":"Excel AI Assistant",
      "teacher":"Teacher full name",
      "template":"1) Template Excel (.xlsx)",
      "data":"2) Data files (1–20 .xlsx)",
      "pickTpl":"Pick template",
      "pickData":"Pick files",
      "run":"Auto fill",
      "api":"Backend URL",
      "done":"Done! File saved.",
      "err":"Error",
    },
  };

  String tr(String k) => (t[lang]?[k]) ?? k;

  Future<void> pickTemplate() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["xlsx"],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => templateFile = res.files.first);
    }
  }

  Future<void> pickData() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["xlsx"],
      allowMultiple: true,
      withData: true,
    );
    if (res != null) {
      final files = res.files;
      if (files.length > 20) {
        setState(() => status = "${tr('err')}: max 20");
        return;
      }
      setState(() => dataFiles = files);
    }
  }

  Future<void> run() async {
    final teacher = teacherCtrl.text.trim();
    if (teacher.isEmpty || templateFile == null || dataFiles.isEmpty) {
      setState(() => status = "${tr('err')}: missing fields");
      return;
    }
    setState(() { busy = true; status = "Processing…"; });

    try {
      final uri = Uri.parse("${apiBase.replaceAll(RegExp(r'/+$'), '')}/process");
      final req = http.MultipartRequest("POST", uri);
      req.fields["teacher_fullname"] = teacher;

      req.files.add(http.MultipartFile.fromBytes(
        "template_file",
        templateFile!.bytes!,
        filename: templateFile!.name,
      ));

      for (final f in dataFiles) {
        req.files.add(http.MultipartFile.fromBytes(
          "data_files",
          f.bytes!,
          filename: f.name,
        ));
      }

      final resp = await req.send();
      if (resp.statusCode != 200) {
        final body = await resp.stream.bytesToString();
        setState(() => status = "${tr('err')}: $body");
        return;
      }

      final bytes = await resp.stream.toBytes();
      // On Android we just open a share/save dialog via FilePicker save is not available universally;
      // so we show the file as a download via "Save As" using FilePicker.
      String filename = "result.xlsx";
      final cd = resp.headers["content-disposition"];
      if (cd != null) {
        final m = RegExp(r'filename="([^"]+)"').firstMatch(cd);
        if (m != null) filename = m.group(1)!;
      }

      final path = await FilePicker.platform.saveFile(
        dialogTitle: tr("done"),
        fileName: filename,
        allowedExtensions: ["xlsx"],
        type: FileType.custom,
        bytes: bytes,
      );

      setState(() => status = path == null ? "Cancelled" : "${tr('done')} ($filename)");
    } catch (e) {
      setState(() => status = "${tr('err')}: $e");
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.lightBlue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(tr("title")),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: lang,
                dropdownColor: const Color(0xFF0f172a),
                items: const [
                  DropdownMenuItem(value:"uz", child: Text("UZ")),
                  DropdownMenuItem(value:"ru", child: Text("RU")),
                  DropdownMenuItem(value:"en", child: Text("EN")),
                ],
                onChanged: (v){ if(v!=null) setState(()=>lang=v); },
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(tr("api"), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                decoration: InputDecoration(
                  hintText: apiBase,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (v) => apiBase = v.trim().isEmpty ? apiBase : v.trim(),
              ),
              const SizedBox(height: 14),

              Text(tr("teacher"), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: teacherCtrl,
                decoration: InputDecoration(
                  hintText: "Qodirov Muhammadullo Shokirjon o‘g‘li",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              ListTile(
                title: Text(tr("template")),
                subtitle: Text(templateFile?.name ?? "—"),
                trailing: FilledButton(onPressed: busy ? null : pickTemplate, child: Text(tr("pickTpl"))),
              ),
              const SizedBox(height: 6),
              ListTile(
                title: Text(tr("data")),
                subtitle: Text(dataFiles.isEmpty ? "—" : "${dataFiles.length} file(s) selected"),
                trailing: FilledButton(onPressed: busy ? null : pickData, child: Text(tr("pickData"))),
              ),
              const SizedBox(height: 14),

              FilledButton(
                onPressed: busy ? null : run,
                child: Text(tr("run")),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                  color: const Color(0xFF0f172a),
                ),
                child: Text(status, style: const TextStyle(color: Colors.white70)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
