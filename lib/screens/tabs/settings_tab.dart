import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String currentLangCode; 
  final Function(String) onLanguageChanged;

  const SettingsTab({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.currentLangCode,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy màu từ Theme đã được set ở HomeScreen
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : Colors.black);
    final primaryColor = const Color(0xFF635AD9);

    // Dictionary ngôn ngữ tại chỗ (hoặc tách ra file riêng)
    final isVi = currentLangCode == 'vi';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(isVi ? "Cài đặt" : "Settings", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // Tắt nút back mặc định
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Giao diện
          Text(isVi ? "Giao diện" : "Appearance", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(
              value: isDarkMode,
              onChanged: onThemeChanged, // Trigger callback về HomeScreen
              activeColor: primaryColor,
              title: Text(isVi ? "Chế độ tối" : "Dark Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dark_mode, color: isDarkMode ? Colors.white : Colors.blue),
              ),
            ),
          ),

          const SizedBox(height: 20),
          
          // Section: Ngôn ngữ & Khác
          Text(isVi ? "Hệ thống" : "System", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Colors.green),
                  ),
                  title: Text(isVi ? "Ngôn ngữ" : "Language", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(isVi ? "Tiếng Việt" : "English", style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _showLanguageDialog(context, textColor, cardColor),
                ),
                Divider(height: 1, color: isDarkMode ? Colors.white12 : Colors.grey[200]),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.orange),
                  ),
                  title: Text(isVi ? "Giới thiệu" : "About", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, Color textColor, Color bgColor) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(currentLangCode == 'vi' ? "Chọn ngôn ngữ" : "Select Language", style: TextStyle(color: textColor)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangOption(context, 'vi', "Tiếng Việt", "assets/vn_flag.png", textColor),
              _buildLangOption(context, 'en', "English", "assets/us_flag.png", textColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(BuildContext context, String code, String name, String? iconPath, Color textColor) {
    final isSelected = currentLangCode == code;
    return ListTile(
      title: Text(name, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF635AD9)) : null,
      onTap: () {
        onLanguageChanged(code); // Trigger callback về HomeScreen
        Navigator.pop(context);
      },
    );
  }
}