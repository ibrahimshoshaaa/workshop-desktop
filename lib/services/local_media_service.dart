import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'local_paths.dart';

class LocalMediaService {
  LocalMediaService(this.paths);
  final LocalPaths paths;
  static const prefix = 'workshop-media://';
  static final validName = RegExp(r'^[a-f0-9]{64}\.img$');
  String _name(String reference) {
    final name = reference.startsWith(prefix)
        ? reference.substring(prefix.length)
        : '${sha256.convert(utf8.encode(reference))}.img';
    if (!validName.hasMatch(name))
      throw const FormatException('مرجع صورة غير صالح');
    return name;
  }

  File fileFor(String reference) =>
      File(p.join(paths.media.path, _name(reference)));
  Future<String> save(List<int> bytes) async {
    await paths.media.create(recursive: true);
    final name = '${sha256.convert(bytes)}.img';
    final file = File(p.join(paths.media.path, name));
    if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
    return '$prefix$name';
  }

  Future<List<String>> saveMultiple(List<List<int>> images) async {
    final result = <String>[];
    for (final image in images) {
      result.add(await save(image));
    }
    return result;
  }

  /// Only this explicit migration action contacts legacy image hosting.
  Future<bool> cacheLegacy(String reference) async {
    final target = fileFor(reference);
    if (await target.exists()) return true;
    if (reference.startsWith(prefix)) return false;
    final uri = Uri.tryParse(reference);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'res.cloudinary.com')
      return false;
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        !(response.headers['content-type'] ?? '').startsWith('image/'))
      return false;
    await paths.media.create(recursive: true);
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(response.bodyBytes, flush: true);
    await temp.rename(target.path);
    return true;
  }
}

/// Displaying orders never downloads images or requires a cloud login.
class LocalOrderImage extends StatelessWidget {
  const LocalOrderImage(
    this.reference, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });
  final String reference;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _resolve(),
    builder: (context, snapshot) {
      final file = snapshot.data;
      if (file == null)
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Tooltip(
              message: 'الصورة القديمة لم تُحفظ محليًا بعد — من الإعدادات',
              child: Icon(Icons.image_not_supported_outlined),
            ),
          ),
        );
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    },
  );
  Future<File?> _resolve() async {
    final store = LocalMediaService(await LocalPaths.load());
    final file = store.fileFor(reference);
    return await file.exists() ? file : null;
  }
}
