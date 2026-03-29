import 'package:flutter/material.dart';

class PremiumScaffold extends StatelessWidget {
  final Widget body;
  final Widget? header; // Custom header widget
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;

  const PremiumScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    const Color(0xFF202533), // Slightly lighter navy for depth
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor, // Solid color for light theme
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (header != null) header!,
              Expanded(child: body),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
