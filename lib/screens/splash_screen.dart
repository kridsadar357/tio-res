import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

/// Professional Splash Screen Widget
/// 
/// Displays the TioRes splash image while the app initializes.
/// Features smooth fade-in/fade-out animations and proper image scaling.
class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({
    super.key,
    required this.child,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  bool _showSplash = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Duration for fade out
      vsync: this,
    );

    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start immediately visible (no fade in) to cover the app
    // Revised logic: 
    // We only need fade-out. So we can simplify.
    // Let's just hold it visible for the duration.
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait minimum splash time (2 seconds) for smooth UX
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    
    // Additional initialization check if needed
    // The app is already initialized in main(), so we just wait
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      // Start fade out animation
      _controller.forward();
      
      // Hide splash after fade out completes
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        widget.child,
        
        // Splash screen overlay - blocks all interactions while visible
        if (_showSplash)
          IgnorePointer(
            ignoring: false, // Block interactions
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Only animate fade out when initialized
                final opacity = _isInitialized
                    ? _fadeOutAnimation.value
                    : 1.0; // Always visible initially
                
                return Opacity(
                  opacity: opacity,
                  child: const _SplashContent(),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Splash Image
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.asset(
                'assets/images/tio_res_splash.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return Container(
                    width: 300.w,
                    height: 300.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 100.sp,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
            
            // Optional: Loading indicator
            SizedBox(height: 40.h),
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

