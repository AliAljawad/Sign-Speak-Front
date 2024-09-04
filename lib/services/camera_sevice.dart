import 'package:camera/camera.dart';

class CameraService {
  Future<CameraDescription> initializeCamera() async {
    final cameras = await availableCameras();
    return cameras.first;
  }
}
