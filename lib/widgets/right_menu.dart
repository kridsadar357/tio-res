import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// MenuItem definition for the right menu
class RightMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<String> requiredRoles; // For future RBAC

  const RightMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.requiredRoles = const [],
  });
}

/// Reusable right drawer menu with 2-column grid layout
class RightMenuWidget extends StatelessWidget {
  final List<RightMenuItem> menuItems;
  final String? currentUserRole; // For future RBAC

  const RightMenuWidget({
    super.key,
    required this.menuItems,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    // Filter items based on role (if roles are defined)
    final visibleItems = menuItems.where((item) {
      if (item.requiredRoles.isEmpty) return true;
      if (currentUserRole == null) return true; // Show all if no role set
      return item.requiredRoles.contains(currentUserRole);
    }).toList();

    return Drawer(
      width: 280.w,
      backgroundColor: Theme.of(context).cardTheme.color,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(
            left: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.yellow
                  : Colors.indigo,
              width: 4,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Text(
                'จัดการโปรแกรม',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.0, // Square buttons
                  ),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    return _buildMenuButton(context, visibleItems[index]);
                  },
                ),
              ),
              // Version footer
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'ResPOS v1.0',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, RightMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          item.onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.yellow.withValues(alpha: 0.3)
                  : Colors.indigo.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 24.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
