import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isDarkMode;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Màu sắc chủ đạo
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final activeColor = const Color(0xFF635AD9);
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.grey.shade600;

    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 20, // Tạo độ bóng đổ sang trọng
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bên trái nút Add
          Row(
            children: [
              _buildNavButton(
                icon: Icons.home_rounded,
                label: isDarkMode ? "Home" : "Trang chủ",
                index: 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavButton(
                icon: Icons.account_balance_wallet_rounded,
                label: isDarkMode ? "Wallet" : "Ví",
                index: 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
          
          const SizedBox(width: 48), // Khoảng trống cho FloatingActionButton

          // Bên phải nút Add
          Row(
            children: [
              _buildNavButton(
                icon: Icons.pie_chart_rounded,
                label: isDarkMode ? "Report" : "Báo cáo",
                index: 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavButton(
                icon: Icons.settings_rounded,
                label: isDarkMode ? "Settings" : "Cài đặt",
                index: 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          // Hiệu ứng đổ màu nền nhạt khi được chọn
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            // Hiệu ứng hiện chữ khi được chọn
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isSelected 
                  ? CrossFadeState.showFirst 
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}