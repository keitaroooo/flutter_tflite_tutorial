import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

typedef void Callback(List<dynamic> list, int h, int w);

class CameraFeed extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final Callback setRecognitions;
  CameraFeed(this.cameras, this.setRecognitions);

  @override
  _CameraFeedState createState() => new _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController? controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    print(widget.cameras);
    if (widget.cameras == null || widget.cameras!.length < 1) {
      print('No Cameras Fount');
    } else {
      controller = new CameraController(
        widget.cameras![0],
        ResolutionPreset.high,
      );
      controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller?.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;
            Tflite.detectObjectOnFrame(
              bytesList: img.planes.map((plane) {
                return plane.bytes;
              }).toList(),
              model: "SSDMobileNet",
              imageHeight: img.height,
              imageWidth: img.width,
              imageMean: 127.5,
              imageStd: 127.5,
              numResultsPerClass: 3,
              threshold: 0.4,
            ).then((recognitions) {
              widget.setRecognitions(recognitions!, img.height, img.width);
              isDetecting = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }

    Size size = MediaQuery.of(context).size;
    double screenH = math.max(size.height, size.width);
    double screenW = math.min(size.height, size.width);
    size = controller!.value.previewSize!;
    double previewH = math.max(size.height, size.width);
    double previewW = math.min(size.height, size.width);
    double screenRatio = screenH / screenW;
    double previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : previewH* screenW / previewW,
      maxWidth:
          screenRatio > previewRatio ? previewW * screenH / previewH : screenW,
      child: CameraPreview(controller!),
    );
  }
}
