import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  const SectionHeader({super.key, required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          if (actionText.isNotEmpty)
            Text(
              actionText, 
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
            ),
        ],
      ),
    );
  }
}

class UtilityItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const UtilityItem({
    super.key, 
    required this.label, 
    required this.icon, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
}