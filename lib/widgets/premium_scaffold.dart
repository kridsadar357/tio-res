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
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: Colors.transparent, // Important for gradient visibility
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF202533), // Slightly lighter navy for depth
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
