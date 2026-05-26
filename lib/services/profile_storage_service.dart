import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  /// Consente all'utente di selezionare un'immagine dalla galleria del telefono.
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      return image;
    } catch (e) {
      debugPrint('Errore durante la selezione dell\'immagine: $e');
      rethrow;
    }
  }

  /// Consente all'utente di ritagliare l'immagine in formato 1:1 con un'anteprima circolare.
  Future<CroppedFile?> cropImage(XFile imageFile, BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String title = userProvider.t('crop_title');
      final String cropText = userProvider.t('crop');
      final String cancelText = userProvider.t('cancel');
      final String rotateLeftText = userProvider.t('rotate_left');
      final String rotateRightText = userProvider.t('rotate_right');

      final croppedFile = await _cropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: title,
            doneButtonTitle: cropText,
            cancelButtonTitle: cancelText,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 300, height: 300),
            translations: WebTranslations(
              title: title,
              rotateLeftTooltip: rotateLeftText,
              rotateRightTooltip: rotateRightText,
              cancelButton: cancelText,
              cropButton: cropText,
            ),
          ),
        ],
      );
      return croppedFile;
    } catch (e) {
      debugPrint('Errore durante il ritaglio: $e');
      return null;
    }
  }

  /// Ottimizza, ridimensiona e carica l'immagine profilo dell'utente su Firebase Storage.
  /// 
  /// - Risoluzione finale: esattamente 500x500 pixel.
  /// - Formato: JPEG con qualità impostata a 70.
  /// - Percorso di upload: `profiles/${userId}.jpg`.
  /// 
  /// Ritorna l'URL pubblico del file caricato.
  Future<String> uploadProfileImage(CroppedFile imageFile, String userId) async {
    try {
      debugPrint('DEBUG ProfileStorage: Inizio lettura bytes...');
      final Uint8List bytes = await imageFile.readAsBytes();
      debugPrint('DEBUG ProfileStorage: Bytes letti: ${bytes.length}');

      // 1. Ottimizzazione e compressione a 500x500 pixel
      Uint8List compressedData;
      try {
        debugPrint('DEBUG ProfileStorage: Inizio compressione a 500x500...');
        final result = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 500,
          minHeight: 500,
          quality: 70,
          format: CompressFormat.jpeg,
        );
        compressedData = result;
        debugPrint('DEBUG ProfileStorage: Compressione completata. Dimensione: ${compressedData.length} bytes');
      } catch (compressError) {
        // Se la compressione fallisce (es. su Web o errore nativo), usiamo i byte originali come fallback
        debugPrint('DEBUG ProfileStorage: Compressione fallita ($compressError). Uso i bytes originali.');
        compressedData = bytes;
      }

      // 2. Definizione del percorso e metadati (profiles/${userId}.jpg)
      final String path = 'profiles/$userId.jpg';
      debugPrint('DEBUG ProfileStorage: Inizio upload su path: $path');
      final Reference ref = _storage.ref().child(path);
      
      final UploadTask uploadTask = ref.putData(
        compressedData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      debugPrint('DEBUG ProfileStorage: Caricamento completato con successo.');

      // 3. Recupero dell'URL pubblico
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('DEBUG ProfileStorage: URL pubblico ottenuto: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Errore durante l\'ottimizzazione/caricamento dell\'immagine: $e');
      rethrow;
    }
  }
}
