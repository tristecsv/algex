import 'package:flutter/material.dart';

class AdjustSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AdjustSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Divider(
                color: cs.primary.withOpacity(0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
