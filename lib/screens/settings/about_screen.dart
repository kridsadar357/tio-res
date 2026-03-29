import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              const Color(0xFF1A1F2B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Placeholder
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues( alpha : 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                      )),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 60.sp,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'ResPOS',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Version 1.0.0 (Beta)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 48.h),

                // Credits
                _buildInfoTile(context, 'Developer', 'ResPOS Team'),
                _buildInfoTile(context, 'Contact', 'support@respos.com'),
                _buildInfoTile(context, 'License', 'MIT License'),

                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Text(
                    '© 2026 ResPOS Inc. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
