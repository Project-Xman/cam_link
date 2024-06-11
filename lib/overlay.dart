import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class ImageProcessingOverlay extends StatefulWidget {
  const ImageProcessingOverlay({super.key});

  @override
  State<ImageProcessingOverlay> createState() => _ImageProcessingOverlayState();
}

class _ImageProcessingOverlayState extends State<ImageProcessingOverlay> {
  static const String _kPortNameOverlay = 'OVERLAY';
  final _receivePort = ReceivePort();
  SendPort? homePort;
  int totalImages = 0;
  int totalImagesProcessed = 0;
  int totalImagesUploaded = 0;

  @override
  void initState() {
    super.initState();
    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameOverlay,
    );
    log("$res : HOME");

    FlutterOverlayWindow.overlayListener.listen((event) {
      log("Current Event: $event"); //Current Event: [1, 1, 1]
      if (event is List) {
        setState(() {
          totalImages = event[0];
          totalImagesProcessed = event[1];
          totalImagesUploaded = event[2];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        elevation: 0.0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.2, // Adjust height
          width: MediaQuery.of(context).size.width * 0.8, // Adjust width
          decoration: const BoxDecoration(
            color: Colors.white54,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageCount(
                    Icons.camera_alt, totalImages, Colors.lightBlue),
                _buildImageCount(
                    Icons.image, totalImagesProcessed, Colors.deepOrange),
                _buildImageCount(
                    Icons.upload, totalImagesUploaded, Colors.lightGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCount(IconData icon, int count, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 30.0,
          color: color,
        ),
        Text('$count', style: TextStyle(fontSize: 14.0, color: color)),
      ],
    );
  }
}
