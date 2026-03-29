import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/menu_category.dart';
import '../../services/database_helper.dart';
import 'manage_category_dialog.dart';

class MenuCategoryListTab extends StatefulWidget {
  const MenuCategoryListTab({super.key});

  @override
  State<MenuCategoryListTab> createState() => _MenuCategoryListTabState();
}

class _MenuCategoryListTabState extends State<MenuCategoryListTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuCategory>>(
      future: DatabaseHelper().getAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined,
                    size: 64.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                SizedBox(height: 16.h),
                Text('No categories found',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 16.sp)),
              ],
            ),
          );
        }

        final categories = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues( alpha : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12.w),
                leading: Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues( alpha : 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withValues( alpha : 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withValues( alpha : 0.3),
                          blurRadius: 12,
                        )
                      ]),
                  child: Center(
                    child: Text(
                      category.name.isNotEmpty
                          ? category.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
                title: Text(category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (ctx) =>
                              ManageCategoryDialog(category: category),
                        );
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(
                                0xFF252836), // Manual dark bg for standard alert
                            title: Text('Delete Category',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            content: Text(
                                'Are you sure? This is irreversible.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style:
                                          TextStyle(color: Colors.redAccent))),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await DatabaseHelper()
                              .deleteMenuCategory(category.id!);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
