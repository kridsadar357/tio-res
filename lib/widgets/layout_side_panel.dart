import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/table_model.dart';
import '../theme/app_theme.dart';

class LayoutSidePanel extends StatelessWidget {
  final List<TableModel> tables;

  const LayoutSidePanel({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final total = tables.length;
    final available = tables.where((t) => t.status == 0).length;
    final occupied = tables.where((t) => t.status == 1).length;
    final cleaning = tables.where((t) => t.status == 2).length;

    return Container(
      width: 220.w, // Reduced from 280.w to fit map better
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Floor Status',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 24.h),
            _buildStatCard(context, 'ทั้งหมด', total.toString(),
                Icons.table_restaurant, Colors.blue),
            SizedBox(height: 12.h),
            _buildStatCard(context, 'ว่าง', available.toString(),
                Icons.check_circle, AppTheme.statusAvailable),
            SizedBox(height: 12.h),
            _buildStatCard(context, 'มีลูกค้า', occupied.toString(), Icons.people,
                AppTheme.statusOccupied),
            SizedBox(height: 12.h),
            _buildStatCard(context, 'กำลังทำความสะอาด', cleaning.toString(),
                Icons.cleaning_services, AppTheme.statusCleaning),
            SizedBox(height: 32.h),
            Text(
              'Legend',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: 16.h),
            _buildLegendItem(context, 'กำแพง', Icons.crop_landscape, Colors.grey),
            _buildLegendItem(
                context, 'ตกแต่ง', Icons.local_florist, Colors.green),
            _buildLegendItem(
                context, 'ทางเข้า', Icons.meeting_room, Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
