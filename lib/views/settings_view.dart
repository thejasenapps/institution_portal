// lib/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/theme_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Obx(() {
            final bool isDark = themeController.isDarkMode.value;
            return SwitchListTile(
              title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
              subtitle: Text(
                isDark
                    ? 'Currently using dark theme'
                    : 'Currently using light theme',
              ),
              value: isDark,
              onChanged: (_) => themeController.toggleTheme(),
            );
          }),
        ],
      ),
    );
  }
}
