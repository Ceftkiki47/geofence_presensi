import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraAbsensiScreen extends StatefulWidget {
  const CameraAbsensiScreen({super.key});

  @override
  State<CameraAbsensiScreen> createState() => _CameraAbsensiScreenState();
}

class _CameraAbsensiScreenState extends State<CameraAbsensiScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      debugPrint('CAMERA INIT ERROR: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile xfile = await _controller!.takePicture();

      final dir = await getTemporaryDirectory();
      final imageFile = File(
        '${dir.path}/absen_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await xfile.saveTo(imageFile.path);

      if (!mounted) return;

      /// KEMBALIKAN FILE KE PIN SCREEN
      Navigator.pop(context, imageFile);
    } catch (e) {
      debugPrint('TAKE PICTURE ERROR: $e');
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Foto Absensi'),
      ),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_controller!),

                /// BUTTON CAPTURE
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isTakingPicture
                                ? Colors.grey
                                : Colors.white,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
