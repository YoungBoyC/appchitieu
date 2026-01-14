import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF635AD9),
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Center(child: Text("Thành Đạt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const Center(child: Text("Gói thành viên thường", style: TextStyle(color: Colors.grey))),
        const SizedBox(height: 30),
        const Divider(),
        _settingTile(Icons.language, "Ngôn ngữ", "Tiếng Việt"),
        _settingTile(Icons.security, "Bảo mật", "PIN & Vân tay"),
        _settingTile(Icons.help_outline, "Hỗ trợ", ""),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () {
          },
        ),
      ],
    );
  }

  Widget _settingTile(IconData icon, String title, String trailing) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(trailing, style: const TextStyle(color: Colors.grey)),
    );
  }
}