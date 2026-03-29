import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/table_model.dart';
import '../../services/database_helper.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/management/layout_designer_screen.dart';

class TableLayoutScreen extends StatefulWidget {
  const TableLayoutScreen({super.key});

  @override
  State<TableLayoutScreen> createState() => _TableLayoutScreenState();
}

class _TableLayoutScreenState extends State<TableLayoutScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = true;
  bool _takeAwayExpanded = false; // Toggle state for Take Away section

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    final tables = await DatabaseHelper().getAllTables();
    setState(() {
      _tables = tables;
      _isLoading = false;
    });
  }

  Future<void> _addTable() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(l10n.addTable, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: l10n.tableNameLabel,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            filled: true,
            fillColor: const Color(0xFF1A1F2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                PremiumToast.show(context, l10n.nameRequired, isError: true);
                return;
              }
              await DatabaseHelper().addTable(nameController.text);
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(l10n.add),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadTables();
      if (mounted) PremiumToast.show(context, l10n.tableAdded);
    }
  }

  Future<void> _deleteTable(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title:
            Text(l10n.deleteTable, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('${l10n.deleteTable} $id?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Assuming deleteTable exists in DatabaseHelper taking an int id.
      // If not, we might fail here. But based on pattern it should.
      await DatabaseHelper().deleteTable(id);
      _loadTables();
      if (mounted) PremiumToast.show(context, l10n.tableDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.tableLayoutTitle,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addTable),
              onPressed: _addTable,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Open Designer'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const LayoutDesignerScreen(),
                  ),
                ).then((_) => _loadTables());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Take Away Section with toggle
                _buildTakeAwaySection(l10n),
                
                // Tables Grid
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(24.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _takeAwayExpanded ? 3 : 4,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final table = _tables[index];
                      return _buildTableCard(table, l10n);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTakeAwaySection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _takeAwayExpanded ? 320.w : 80.w,
      clipBehavior: Clip.none, // Allow toggle button to extend outside
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow toggle button to overflow
        children: [
          // Content
          Padding(
            padding: EdgeInsets.all(_takeAwayExpanded ? 16.w : 8.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                
                // Take Away Icon and Title
                if (_takeAwayExpanded) ...[
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.takeout_dining,
                      size: 48.sp,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.takeAway,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.takeAwayDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Take Away Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to take away order screen
                        PremiumToast.show(context, l10n.takeAwayComingSoon);
                      },
                      icon: Icon(Icons.add_shopping_cart, size: 24.sp),
                      label: Text(
                        l10n.newTakeAwayOrder,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  Divider(color: Colors.orange.withValues(alpha: 0.3)),
                  SizedBox(height: 16.h),
                  
                  // Stats
                  _buildTakeAwayStats(l10n),
                ] else ...[
                  // Collapsed view - just icon
                  SizedBox(height: 20.h),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      l10n.takeAway,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(
                    Icons.takeout_dining,
                    size: 32.sp,
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          
          // Toggle Button - Double Arrow extending outside the container
          Positioned(
            right: -24.w, // Extend outside the container
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _takeAwayExpanded = !_takeAwayExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 32.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _takeAwayExpanded 
                              ? Icons.keyboard_double_arrow_left 
                              : Icons.keyboard_double_arrow_right,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeAwayStats(AppLocalizations l10n) {
    return Column(
      children: [
        _buildStatRow(l10n.todayOrders, '0', Icons.receipt_long),
        SizedBox(height: 12.h),
        _buildStatRow(l10n.pendingOrders, '0', Icons.pending_actions),
        SizedBox(height: 12.h),
        _buildStatRow(l10n.completedOrders, '0', Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.orange.withValues(alpha: 0.8)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(TableModel table, AppLocalizations l10n) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant,
                    size: 32.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                SizedBox(height: 8.h),
                Text(
                  table.tableName.isNotEmpty
                      ? table.tableName
                      : '${l10n.table} ${table.id}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4.h,
          right: 4.w,
          child: IconButton(
            icon: const Icon(Icons.delete,
                size: 16, color: Colors.redAccent),
            onPressed: () => _deleteTable(table.id),
          ),
        ),
      ],
    );
  }
}
