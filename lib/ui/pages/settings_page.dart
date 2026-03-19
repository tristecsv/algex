import 'package:algex/core/model/settings.dart';
import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/widgets/adjust/adjust_visualization.dart';
import 'package:algex/ui/widgets/adjust/adjust_convergence.dart';
import 'package:algex/ui/widgets/algex_sliver_appbar.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: CustomScrollView(
        slivers: [
          AlgexSliverAppBar(
            onAction: () =>
                SettingsScope.of(context).settings = const Settings(),
            title: 'Configuración',
            actionIcon: Icons.restart_alt_rounded,
            actionTooltip: 'Restablecer valores',
            showBackButton: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const AdjustConvergence(),
                const SizedBox(height: 12),
                const AdjustVisualization(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
