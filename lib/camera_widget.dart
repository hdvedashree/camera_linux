import 'dart:async';
import 'dart:typed_data';

import 'package:camera_linux/camera_feed_wrapper.dart';
import 'package:flutter/material.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  StreamSubscription<Uint8List>? _cameraFeedSubscription;
  Uint8List? _lastFrame;
  final bool _isStreaming = false;

  final List<Uint8List> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    startStreaming();
  }

  Future<void> startStreaming() async {
    _cameraFeedSubscription =
        CameraFeedWrapper.getCameraFeed()?.listen((frame) {
      setState(() {
        _lastFrame = frame;
      });
    });
  }

  void _stopStreaming() {
    _cameraFeedSubscription?.cancel();
    _cameraFeedSubscription = null;
    CameraFeedWrapper.stopCameraFeed();
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Camera Widget",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Column(
          children: [
            const SizedBox(height: 40),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                color: Colors.black,
                              ),
                              width: 600,
                              height: 400,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Visibility(
                                    visible:
                                        _lastFrame == null && !_isStreaming,
                                    child: const Text(
                                      "Loading camera preview",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.white),
                                    ),
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_lastFrame != null)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(60),
                                          child: Image.memory(
                                            _lastFrame!,
                                            width: 600,
                                            height: 400,
                                            gaplessPlayback: true,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              )),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: () {
                              // Add your onPressed code here!
                              setState(() {
                                _capturedImages.add(_lastFrame!);
                              });
                            },
                            child: const Text('Capture'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: _CapturedImagesList(_capturedImages))
                ],
              ),
            ),
          ],
        ));
  }
}

class _CapturedImagesList extends StatelessWidget {
  final List<Uint8List> capturedImages;

  const _CapturedImagesList(this.capturedImages);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: capturedImages.length,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, //_filteredList?.length == 1 ? 1 : 2,
          mainAxisSpacing: 40,
          crossAxisSpacing: 40),
      itemBuilder: (context, index) {
        return Image.memory(capturedImages[index], fit: BoxFit.cover);
      },
    );
  }
}
