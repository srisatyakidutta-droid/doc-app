import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const MaterialApp(home: ConverterScreen()));

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});
  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextRecognizer _recognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _text = "";
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _loading = true; });

    final recognized = await _recognizer.processImage(InputImage.fromFilePath(picked.path));
    setState(() {
      _text = recognized.text.isEmpty ? "কোনো টেক্সট পাওয়া যায়নি।" : recognized.text;
      _loading = false;
    });
  }

  void _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (ctx) => pw.Text(_text, style: const pw.TextStyle(fontSize: 14))));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'document.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to Typed PDF')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () => _pick(ImageSource.camera), child: const Text('ক্যামেরা'))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(onPressed: () => _pick(ImageSource.gallery), child: const Text('গ্যালারি'))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_image != null) Image.file(_image!, height: 180),
                  const SizedBox(height: 15),
                  TextField(
                    maxLines: 8,
                    controller: TextEditingController(text: _text),
                    onChanged: (val) => _text = val,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'পড়া টেক্সট (এডিট করতে পারেন)'),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(onPressed: _exportPdf, child: const Text('PDF ডাউনলোড করুন')),
                ],
              ),
            ),
    );
  }
}
