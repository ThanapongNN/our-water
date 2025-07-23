// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OurWater(),
  ));
}

class OurWater extends StatefulWidget {
  const OurWater({super.key});

  @override
  State<OurWater> createState() => _OurWaterState();
}

class _OurWaterState extends State<OurWater> {
  ui.Image? _image;
  img.Image? _decodedImage;
  Uint8List? _imageBytes;
  Color? _selectedColor;
  Offset? _tapPosition;
  int _radius = 20;
  BoxConstraints? _imageConstraints;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _imageBytes = await pickedFile.readAsBytes();
      final decoded = img.decodeImage(_imageBytes!);
      if (decoded != null) {
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(_imageBytes!, (result) => completer.complete(result));
        _decodedImage = decoded;
        _image = await completer.future;
        setState(() {});
      }
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _imageBytes = await pickedFile.readAsBytes();
      final decoded = img.decodeImage(_imageBytes!);
      if (decoded != null) {
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(_imageBytes!, (result) => completer.complete(result));
        _decodedImage = decoded;
        _image = await completer.future;
        setState(() {});
      }
    }
  }

  void _getColorFromPosition(Offset position, BoxConstraints constraints) {
    if (_decodedImage == null || _image == null) return;

    final imgWidth = _image!.width.toDouble();
    final imgHeight = _image!.height.toDouble();

    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;

    double scale = (imgWidth / imgHeight > containerWidth / containerHeight) ? containerWidth / imgWidth : containerHeight / imgHeight;

    double displayWidth = imgWidth * scale;
    double displayHeight = imgHeight * scale;

    double offsetX = (containerWidth - displayWidth) / 2;
    double offsetY = (containerHeight - displayHeight) / 2;

    double relativeX = (position.dx - offsetX) / displayWidth;
    double relativeY = (position.dy - offsetY) / displayHeight;

    if (relativeX < 0 || relativeX > 1 || relativeY < 0 || relativeY > 1) return;

    int centerX = (relativeX * _decodedImage!.width).round();
    int centerY = (relativeY * _decodedImage!.height).round();

    final bytes = _decodedImage!.getBytes(order: img.ChannelOrder.rgb);

    int totalR = 0, totalG = 0, totalB = 0, count = 0;

    for (int dy = -_radius; dy <= _radius; dy++) {
      for (int dx = -_radius; dx <= _radius; dx++) {
        int px = centerX + dx;
        int py = centerY + dy;

        if (px >= 0 && py >= 0 && px < _decodedImage!.width && py < _decodedImage!.height && (dx * dx + dy * dy <= _radius * _radius)) {
          final index = (py * _decodedImage!.width + px) * 3;
          totalR += bytes[index];
          totalG += bytes[index + 1];
          totalB += bytes[index + 2];
          count++;
        }
      }
    }

    if (count > 0) {
      final avgR = (totalR / count).round();
      final avgG = (totalG / count).round();
      final avgB = (totalB / count).round();
      setState(() {
        _selectedColor = Color.fromARGB(255, avgR, avgG, avgB);
        _tapPosition = position;
      });
    }
  }

  String getTotalHardness(int g) {
    if (g > 90) {
      return 'Not Detected';
    } else if (g < 59) {
      return 'Out of Range';
    }

    return (((102 - _selectedColor!.green) - 6.3544) / 0.7144).toStringAsFixed(2);
  }

  String getChloride(int g) {
    if (g < 148) {
      return 'Not Detected';
    } else if (g > 185) {
      return 'Out of Range';
    }
    return (((_selectedColor!.green - 140) - 7.8466) / 0.3557).toStringAsFixed(2);
  }

  String getNitrate(int g) {
    if (g > 143) {
      return 'Not Detected';
    } else if (g < 39) {
      return 'Out of Range';
    }
    return (((195 - _selectedColor!.green) - 51.926) / 5.7136).toStringAsFixed(2);
  }

  String getNitrite(int g) {
    if (g > 165) {
      return 'Not Detected';
    } else if (g < 119) {
      return 'Out of Range';
    }
    return (((195 - _selectedColor!.green) - 30.081) / 44.094).toStringAsFixed(2);
  }

  String getFluoride(int g) {
    if (g > 60) {
      return 'Not Detected';
    } else if (g < 5) {
      return 'Out of Range';
    }
    return (((120 - _selectedColor!.green) - 57.856) / 383.67).toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Our Water', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_image != null)
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _imageConstraints = constraints;
                        return GestureDetector(
                          onTapDown: (details) {
                            _getColorFromPosition(details.localPosition, constraints);
                          },
                          child: Container(
                            color: Colors.grey.shade300,
                            child: Stack(
                              children: [
                                Center(child: RawImage(image: _image)),
                                if (_tapPosition != null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: CirclePainter(
                                        position: _tapPosition,
                                        radius: _radius.toDouble(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Text('รัศมีการหาค่าสี: $_radius px'),
                      Slider(
                        value: _radius.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '$_radius',
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _radius = value.round();
                            if (_tapPosition != null && _imageConstraints != null) {
                              _getColorFromPosition(_tapPosition!, _imageConstraints!);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (_selectedColor != null)
                Container(
                  height: 30,
                  color: _selectedColor,
                  alignment: Alignment.center,
                  child: Text(
                    'R: ${_selectedColor!.red}, G: ${_selectedColor!.green}, B: ${_selectedColor!.blue}',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              if (_selectedColor != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Hardness : '),
                          Text('Chloride : '),
                          Text('Nitrate : '),
                          Text('Nitrite : '),
                          Text('Fluoride : '),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getTotalHardness(_selectedColor!.green)),
                          Text(getChloride(_selectedColor!.green)),
                          Text(getNitrate(_selectedColor!.green)),
                          Text(getNitrite(_selectedColor!.green)),
                          Text(getFluoride(_selectedColor!.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFDCDCDC),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: BorderSide(color: Colors.blue)),
                    ),
                    child: FittedBox(
                      child: Row(children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'เลือกจากอัลบั้ม',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: FittedBox(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'ถ่ายรูป',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Offset? position;
  final double radius;

  CirclePainter({this.position, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    if (position != null) {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position!, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
