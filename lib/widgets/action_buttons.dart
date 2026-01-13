import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onTopUp;
  final VoidCallback onTransfer;

  const ActionButtons({
    super.key,
    required this.onTopUp,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            "Nạp tiền",
            Icons.add_to_photos_rounded,
            onTopUp,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionItem(
            "Chuyển tiền",
            Icons.send_rounded,
            onTransfer,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7B88FF)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}