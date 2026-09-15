import 'dart:typed_data';

/// A file the admin chose for upload, already read into memory.
///
/// Deliberately free of any `file_picker` type: the picker is a presentation
/// concern, and reading the bytes up front keeps the upload path identical on
/// web (where there is no file path) and on desktop/mobile. Uploads are capped
/// at 10 MB by the backend, so holding the bytes in memory is safe.
class PickedDocument {
  const PickedDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}
