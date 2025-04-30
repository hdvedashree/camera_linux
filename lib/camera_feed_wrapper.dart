import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


class CameraFeedWrapper {
  static Process? _cameraProcess;
  static StreamController<Uint8List>? _controller;

  static Stream<Uint8List>? getCameraFeed() {
    _controller = StreamController<Uint8List>();
    final List<int> buffer = [];
    final List<int> delimiter = utf8.encode('END_OF_FRAME\n');

    try{
      Process.start('assets/script/camera_feed', []).then((Process process) {
        _cameraProcess = process;

        process.stdout.listen((List<int> data) async {
          buffer.addAll(data);  // Add incoming data to the buffer

          while (true) {
            // Find the delimiter in the buffer
            int delimiterIndex = _indexOfSubList(buffer, delimiter);
            if (delimiterIndex == -1) break;

            // Extract the frame data up to the delimiter
            List<int> frameData = buffer.sublist(0, delimiterIndex);
            _controller?.add(Uint8List.fromList(frameData));

            // Remove the processed data and the delimiter from the buffer
            buffer.removeRange(0, delimiterIndex + delimiter.length);
          }
        });

        process.stderr.listen((List<int> data) {
          String errorMessage = utf8.decode(data);
          print(errorMessage);
        });

        process.exitCode.then((int code) {
          _controller?.close();  // Close the stream when the process exits
        });
      });
    }catch(e){
      print(e.toString());
    }

    return _controller?.stream;
  }

  static void stopCameraFeed() {
    if (_cameraProcess != null) {
      _cameraProcess?.kill();  // Terminate the Python process
      _controller?.close();   // Close the stream controller
    }
  }

  static int _indexOfSubList(List<int> list, List<int> subList) {
    for (int i = 0; i <= list.length - subList.length; i++) {
      bool found = true;
      for (int j = 0; j < subList.length; j++) {
        if (list[i + j] != subList[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}
