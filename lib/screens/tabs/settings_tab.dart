import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String currentLangCode; // Mã ngôn ngữ hiện tại (vi/en)
  final Function(String) onLanguageChanged; // Hàm gọi khi đổi ngôn ngữ

  const SettingsTab({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.currentLangCode,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final primaryColor = const Color(0xFF635AD9);

    // Dictionary đơn giản để hiển thị text trong tab này
    final String title = currentLangCode == 'vi' ? "Cài đặt" : "Settings";
    final String darkModeText = currentLangCode == 'vi' ? "Chế độ tối" : "Dark Mode";
    final String langText = currentLangCode == 'vi' ? "Ngôn ngữ" : "Language";
    final String currentLangName = currentLangCode == 'vi' ? "Tiếng Việt" : "English";
    final String aboutText = currentLangCode == 'vi' ? "Giới thiệu" : "About";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(title, style: TextStyle(color: textColor)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ===== DARK MODE =====
          Card(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(
              value: isDarkMode,
              onChanged: onThemeChanged,
              title: Text(darkModeText, style: TextStyle(color: textColor)),
              secondary: Icon(Icons.dark_mode, color: primaryColor),
            ),
          ),

          const SizedBox(height: 16),

          /// ===== LANGUAGE =====
          Card(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Icon(Icons.language, color: primaryColor),
              title: Text(langText, style: TextStyle(color: textColor)),
              subtitle: Text(currentLangName, style: const TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context),
            ),
          ),

          const SizedBox(height: 16),

          /// ===== ABOUT =====
          Card(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: primaryColor),
              title: Text(aboutText, style: TextStyle(color: textColor)),
              subtitle: Text(currentLangCode == 'vi' 
                ? "App Quản Lý Chi Tiêu Cá Nhân" 
                : "Personal Expense Manager App"),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final primaryColor = const Color(0xFF635AD9);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(currentLangCode == 'vi' ? "Chọn ngôn ngữ" : "Select Language", 
            style: TextStyle(color: textColor)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Tiếng Việt", style: TextStyle(color: textColor)),
                trailing: currentLangCode == 'vi' ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  onLanguageChanged('vi');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("English", style: TextStyle(color: textColor)),
                trailing: currentLangCode == 'en' ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  onLanguageChanged('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}