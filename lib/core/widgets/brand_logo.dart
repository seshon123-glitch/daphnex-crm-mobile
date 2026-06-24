import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DaphnexLogoMark extends StatelessWidget {
  const DaphnexLogoMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331769E0),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

class DaphnexWordmark extends StatelessWidget {
  const DaphnexWordmark({
    super.key,
    this.compact = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final bool compact;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Daphnex CRM',
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          compact ? 'Mobile workspace' : 'Mobile workspace for growing teams',
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
