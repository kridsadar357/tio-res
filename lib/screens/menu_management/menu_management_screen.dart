import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/premium_scaffold.dart';
import 'menu_item_list_tab.dart';
import 'menu_category_list_tab.dart';
import 'manage_item_screen.dart';
import 'manage_category_dialog.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      header: _buildHeader(),
      body: Column(
        children: [
          // Tab Bar Container
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: const Color(0xFF252836), // Dark surface for tab track
              borderRadius: BorderRadius.circular(50.r), // Full pill shape
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab, // Ensure full width
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues( alpha : 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(50.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues( alpha : 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              unselectedLabelColor: Colors.white54,
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              splashBorderRadius: BorderRadius.circular(50.r),
              dividerColor: Colors.transparent,
              padding: EdgeInsets.all(4.w),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.menuItems),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.categories),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MenuItemListTab(searchQuery: _searchQuery),
                const MenuCategoryListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues( alpha : 0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20.sp),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchItems,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  )
                : Text(
                    AppLocalizations.of(context)!.menuManagement,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
          if (!_isSearching && _tabController.index == 0)
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues( alpha : 0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          if (!_isSearching) SizedBox(width: 16.w),
          if (!_isSearching)
            ElevatedButton.icon(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                _tabController.index == 0
                    ? AppLocalizations.of(context)!.addItem
                    : AppLocalizations.of(context)!.addCategory,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                elevation: 4,
                shadowColor:
                    Theme.of(context).colorScheme.secondary.withValues( alpha : 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onFabPressed() {
    if (_tabController.index == 0) {
      // Add Item
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (context) => const ManageItemScreen()),
      ).then((_) => setState(() {}));
    } else {
      // Add Category
      showDialog<void>(
        context: context,
        builder: (context) => const ManageCategoryDialog(),
      ).then((_) => setState(() {}));
    }
  }
}
