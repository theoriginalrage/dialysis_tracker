import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraSmokeTestPage extends StatefulWidget {
  const CameraSmokeTestPage({super.key});
  @override
  State<CameraSmokeTestPage> createState() => _CameraSmokeTestPageState();
}

class _CameraSmokeTestPageState extends State<CameraSmokeTestPage> {
  final _picker = ImagePicker();
  XFile? _photo;
  String? _err;

  Future<void> _openCamera() async {
    setState(() => _err = null);

    // Request runtime permission explicitly
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        setState(() => _err = 'Camera permission not granted');
      }
      return;
    }

    try {
      final pic = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      setState(() => _photo = pic);
    } catch (e) {
      setState(() => _err = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Smoke Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_photo != null) Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Saved: ${_photo!.path}',
                  textAlign: TextAlign.center),
            ),
            if (_err != null)
              Text('Error: $_err', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openCamera,
              child: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

