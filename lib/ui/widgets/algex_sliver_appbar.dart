import 'package:flutter/material.dart';

class AlgexSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;
  final bool showBackButton;

  const AlgexSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isCompact = screenWidth < 440;
    final double titleSize = screenWidth * 0.040;
    final double subtitleSize = screenWidth * 0.040;
    final double iconSize = screenWidth * 0.06;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              tooltip: 'Regresar',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        if (onAction != null && actionIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: actionTooltip,
              onPressed: onAction,
              icon: Icon(
                actionIcon,
                color: Colors.white,
                size: iconSize.clamp(20, 30),
              ),
            ),
          ),
      ],
      title: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize.clamp(16, 22),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: subtitleSize.clamp(14, 18),
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize.clamp(16, 24),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  Text(
                    '  -  ',
                    style: TextStyle(
                      fontSize: subtitleSize.clamp(14, 20),
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: subtitleSize.clamp(14, 20),
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              ],
            ),
    );
  }
}
