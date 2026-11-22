import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Avatar bulat: foto dari tautan (atau bytes yang baru dipilih), dan inisial
/// nama jika belum ada foto atau fotonya gagal dimuat.
class AvatarCircle extends StatelessWidget {
  final String inisial;
  final String? url;

  /// Foto yang baru dipilih dan belum diunggah. Didahulukan dari [url].
  final Uint8List? bytes;
  final double size;

  const AvatarCircle({
    super.key,
    required this.inisial,
    this.url,
    this.bytes,
    this.size = 56,
  });

  Widget _inisial() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primary,
      child: Text(
        inisial,
        style: AppText.avatar.copyWith(fontSize: size * 0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget isi;
    if (bytes != null) {
      isi = Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover);
    } else if (url != null) {
      isi = Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _inisial(),
      );
    } else {
      isi = _inisial();
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: isi));
  }
}
