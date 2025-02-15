import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Water',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ColorPickerFromImage(),
    );
  }
}

class ColorPickerFromImage extends StatefulWidget {
  const ColorPickerFromImage({super.key});

  @override
  State<ColorPickerFromImage> createState() => _ColorPickerFromImageState();
}

class _ColorPickerFromImageState extends State<ColorPickerFromImage> {
  File? _imageFile;
  ui.Image? _image;
  Color _pickedColor = Colors.black;
  final ImagePicker _picker = ImagePicker();
  GlobalKey imageKey = GlobalKey(); // ใช้เก็บขนาดของรูปภาพที่แสดงผล

  int r = 0;
  int g = 0;
  int b = 0;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _loadImage(File file) async {
    final data = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  Future<void> _getColorAtTap(TapDownDetails details) async {
    if (_image == null || _imageFile == null) return;

    // ขนาดของ widget ที่แสดงภาพ
    final RenderBox renderBox = imageKey.currentContext!.findRenderObject() as RenderBox;
    final Size widgetSize = renderBox.size;

    // ขนาดของรูปภาพต้นฉบับ
    final int imageWidth = _image!.width;
    final int imageHeight = _image!.height;

    // ตำแหน่งที่แตะบน widget
    double tapX = details.localPosition.dx;
    double tapY = details.localPosition.dy;

    // แปลงพิกัดจากขนาดของ widget ไปยังขนาดของรูปภาพต้นฉบับ
    double scaleX = imageWidth / widgetSize.width;
    double scaleY = imageHeight / widgetSize.height;

    int imageX = (tapX * scaleX).toInt();
    int imageY = (tapY * scaleY).toInt();

    // ดึงข้อมูลสีจากตำแหน่งที่แปลงแล้ว
    ByteData? byteData = await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    Uint8List imageBytes = byteData.buffer.asUint8List();
    int bytesPerPixel = 4;

    int index = (imageY * imageWidth + imageX) * bytesPerPixel;
    if (index >= 0 && index + 3 < imageBytes.length) {
      r = imageBytes[index];
      g = imageBytes[index + 1];
      b = imageBytes[index + 2];

      setState(() {
        _pickedColor = Color.fromARGB(255, r, g, b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Our Water')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null
                ? GestureDetector(
                    key: imageKey,
                    onTapDown: _getColorAtTap,
                    child: Image.file(_imageFile!),
                  )
                : Text('ไม่มีรูปภาพ'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('เลือกรูปภาพ'),
            ),
            SizedBox(height: 20),
            Text(
              'RGB: $r, $g, $b',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              color: _pickedColor,
            ),
          ],
        ),
      ),
    );
  }
}
