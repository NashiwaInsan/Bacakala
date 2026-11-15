import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Bar progres tipis membulat. [value] antara 0 dan 1.
class ProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const ProgressBar({super.key, required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.primarySoft, // track
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary, // isi
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}
