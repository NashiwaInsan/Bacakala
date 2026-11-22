import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Navigasi bawah: Beranda, Rak, Klub, Statistik, Profil.
///
/// Tab Klub dan Statistik selalu dibuka lewat route bersama ('/klub' dan
/// '/statistik'). Tab lain memakai [onTap] dari halaman induk; jika [onTap]
/// tidak diisi, tab dibuka lewat route di [_routes].
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  static const int klubIndex = 2;
  static const int statistikIndex = 3;

  static const _item = <(String, IconData)>[
    ('Beranda', Icons.home_outlined),
    ('Rak', Icons.collections_bookmark_outlined),
    ('Klub', Icons.people_outline),
    ('Statistik', Icons.bar_chart),
    ('Profil', Icons.person_outline),
  ];

  static const _routes = ['/home', '/rak', '/klub', '/statistik', '/profile'];

  void _handleTap(BuildContext context, int i) {
    if (i == currentIndex) return;

    final pakaiRoute = onTap == null || i == klubIndex || i == statistikIndex;
    if (pakaiRoute) {
      Navigator.pushReplacementNamed(context, _routes[i]);
    } else {
      onTap!(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: [
              for (var i = 0; i < _item.length; i++)
                Expanded(child: _buildItem(context, i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int i) {
    final aktif = i == currentIndex;
    final warna = aktif ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () => _handleTap(context, i),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pil hijau muda di belakang ikon untuk item aktif
          Container(
            width: 64,
            height: 34,
            decoration: BoxDecoration(
              color: aktif ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(_item[i].$2, size: 26, color: warna),
          ),
          const SizedBox(height: 4),
          Text(
            _item[i].$1,
            style: aktif ? AppText.navActive : AppText.navInactive,
          ),
        ],
      ),
    );
  }
}
