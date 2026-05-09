import 'dart:io';

class StorageService {
  Future<String?> uploadImage(File imageFile, String roomId) async {
    // Mock for Safe Mode
    await Future.delayed(const Duration(seconds: 1));
    return "https://picsum.photos/400/400";
  }
}
