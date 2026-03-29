import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/menu_item.dart';
import '../../models/menu_category.dart';
import '../../services/database_helper.dart';

import '../../widgets/menu_item_image.dart';

import '../../utils/currency_helper.dart';
import 'manage_item_screen.dart';

class MenuItemListTab extends StatefulWidget {
  final String? searchQuery;
  const MenuItemListTab({super.key, this.searchQuery});

  @override
  State<MenuItemListTab> createState() => _MenuItemListTabState();
}

class _MenuItemListTabState extends State<MenuItemListTab> {
  int? _selectedFilterCategoryId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filter
        _buildCategoryFilter(),
        Divider(height: 1, thickness: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        // Grid
        Expanded(
          child: FutureBuilder<List<MenuItem>>(
            future: (widget.searchQuery != null &&
                    widget.searchQuery!.isNotEmpty)
                ? DatabaseHelper().getAllMenuItems().then((items) => items
                    .where((i) =>
                        i.name
                            .toLowerCase()
                            .contains(widget.searchQuery!.toLowerCase()) ||
                        (i.nameTh != null &&
                            i.nameTh!.contains(widget.searchQuery!)))
                    .toList())
                : (_selectedFilterCategoryId == null
                    ? DatabaseHelper().getAllMenuItems()
                    : DatabaseHelper()
                        .getMenuItemsByCategory(_selectedFilterCategoryId!)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood_outlined,
                          size: 64.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      SizedBox(height: 16.h),
                      Text('No items found',
                          style: TextStyle(
                              fontSize: 16.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                );
              }

              final items = snapshot.data!;
              int crossAxisCount = 8;
              if (MediaQuery.of(context).size.width < 1000) {
                crossAxisCount = 6;
              }
              if (MediaQuery.of(context).size.width < 600) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                padding: EdgeInsets.all(16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: FutureBuilder<List<MenuCategory>>(
        future: DatabaseHelper().getAllCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final categories = snapshot.data!;

          return SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedFilterCategoryId == null;
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: _buildFilterChip('All', isSelected,
                        () => setState(() => _selectedFilterCategoryId = null)),
                  );
                }
                final category = categories[index - 1];
                final isSelected = _selectedFilterCategoryId == category.id;

                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: _buildFilterChip(
                      category.name,
                      isSelected,
                      () => setState(
                          () => _selectedFilterCategoryId = category.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return LayoutBuilder(builder: (context, constraints) {
      return InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (context) => ManageItemScreen(item: item)),
          );
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color, // Premium dark glass
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16.r)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16.r)),
                          child: MenuItemImage(
                            imagePath: item.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Edit/Delete overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => _confirmDelete(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                                  border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
                            ),
                            child: Icon(Icons.close,
                                size: 14.sp, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      // Status Badge (Sold Out)
                      if (item.status == 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16.r)),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.2,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(4.r)),
                                  child: Text('SOLD OUT',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Details
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                height: 1.2,
                                color: item.status == 0
                                    ? Colors.white38
                                    : Colors.white,
                                decoration: item.status == 0
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: Colors.white38,
                              ),
                            ),
                            if (item.nameTh != null && item.nameTh!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  item.nameTh!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyHelper.format(context, item.price),
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                shadows: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  )
                                ]),
                          ),
                          const Spacer(),
                          if (item.isBuffetIncluded)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E096)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                    color: const Color(0xFF00E096)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'BUFFET',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00E096),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Delete Item', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to delete "${item.name}"?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper().deleteMenuItem(item.id!);
      setState(() {});
    }
  }
}
