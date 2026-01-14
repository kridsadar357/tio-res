import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';
import '../models/table_model.dart';
import '../models/layout_object_model.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

class VisualFloorPlan extends StatelessWidget {
  final List<TableModel> tables;
  final List<LayoutObjectModel> objects;
  final Function(TableModel)? onTableTap;
  final Function(LayoutObjectModel)? onObjectTap;
  final bool isEditable;
  final Function(String, double, double)? onDrop; // type, x, y
  final TransformationController? transformationController;
  final GlobalKey? canvasKey;
  // Drag callbacks for editable mode could be more complex, but for now we might keep drag logic in parent or move here?
  // Moving drag logic here is better for encapsulation.
  final Function(TableModel, DragUpdateDetails)? onTableDragUpdate;
  final Function(LayoutObjectModel, DragUpdateDetails)? onObjectDragUpdate;
  final Function(TableModel)? onTablePanStart;
  final Function(LayoutObjectModel)? onObjectPanStart;

  final TableModel? selectedTable;
  final LayoutObjectModel? selectedObject;

  const VisualFloorPlan({
    super.key,
    required this.tables,
    required this.objects,
    this.onTableTap,
    this.onObjectTap,
    this.isEditable = false,
    this.onDrop,
    this.transformationController,
    this.canvasKey,
    this.onTableDragUpdate,
    this.onObjectDragUpdate,
    this.onTablePanStart,
    this.onObjectPanStart,
    this.selectedTable,
    this.selectedObject,
  });

  @override
  Widget build(BuildContext context) {
    const double canvasWidth = 2000.0;
    const double canvasHeight = 1500.0;

    return Container(
      color: Colors.transparent, // Allow parent gradient to show
      child: InteractiveViewer(
        transformationController: transformationController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 4.0,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) => isEditable,
          onAcceptWithDetails: (details) {
            if (!isEditable || onDrop == null) return;
            final renderBox =
                canvasKey?.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPos = renderBox.globalToLocal(details.offset);
              onDrop!(details.data, localPos.dx, localPos.dy);
            }
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              key: canvasKey,
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                image: const DecorationImage(
                  image: AssetImage('assets/images/grid_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none, // Allow objects to extend slightly
                children: [
                  // Objects bottom, Tables top usually. Or sorted by z-index if managed.
                  ...objects.map((obj) => _buildObject(obj)),
                  ...tables.map((table) => _buildTable(table)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable(TableModel table) {
    final isSelected = selectedTable?.id == table.id;

    Widget content = Container(
      width: table.width,
      height: table.height,
      decoration: BoxDecoration(
          color: isEditable
              ? Color(table.color)
              : _getTableColor(table.status, table.color),
          shape: table.shape == 'round' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              table.shape == 'rectangle' ? BorderRadius.circular(8) : null,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Center(
        child: Text(table.tableName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

    if (isEditable) {
      return Positioned(
        left: table.x,
        top: table.y,
        child: GestureDetector(
          onPanStart: (details) => onTablePanStart?.call(table),
          onPanUpdate: (details) => onTableDragUpdate?.call(table, details),
          onTap: () => onTableTap?.call(table),
          behavior: HitTestBehavior.translucent,
          child: content,
        ),
      );
    } else {
      return Positioned(
        left: table.x,
        top: table.y,
        child: GestureDetector(
          onTap: () => onTableTap?.call(table),
          child: content,
        ),
      );
    }
  }

  Widget _buildObject(LayoutObjectModel obj) {
    final isSelected = selectedObject == obj;
    final double padding = 10.0; // Extend hit area by 10px each side

    // Calculate dimensions including padding
    final double realW = obj.width + (padding * 2);
    final double realH = obj.height + (padding * 2);
    // Bounding box size (diagonal) to accommodate any rotation
    final double diag = sqrt((realW * realW) + (realH * realH));

    // Center point of the object
    final double cx = obj.x + (obj.width / 2);
    final double cy = obj.y + (obj.height / 2);

    // 1. Visual Content
    Widget visualContent = Container(
      width: obj.width,
      height: obj.height,
      decoration: BoxDecoration(
        color: obj.color != null ? Color(obj.color!) : Colors.grey,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: (obj.iconPoint != null && obj.iconPoint != 0)
          ? Center(
              child: FaIcon(
                IconHelper.getIconByCodePoint(obj.iconPoint) ??
                    const IconData(0xe000, fontFamily: 'MaterialIcons'),
                color: Colors.white,
                size: min(obj.width, obj.height) * 0.6,
              ),
            )
          : obj.type == 'plant'
              ? const Icon(Icons.local_florist, color: Colors.green)
              : null,
    );

    // 2. Touch Wrapper with explicit size (contains transparent padding)
    Widget touchWrapper = Container(
      width: realW,
      height: realH,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: visualContent,
    );

    // 3. Rotation
    Widget rotated = Transform.rotate(
      angle: obj.rotation,
      child: touchWrapper,
    );

    if (isEditable) {
      return Positioned(
        // Center the larger bounding box on the object's center
        left: cx - (diag / 2),
        top: cy - (diag / 2),
        width: diag,
        height: diag,
        child: GestureDetector(
          onPanStart: (details) => onObjectPanStart?.call(obj),
          onPanUpdate: (details) => onObjectDragUpdate?.call(obj, details),
          onTap: () => onObjectTap?.call(obj),
          behavior: HitTestBehavior
              .translucent, // Allow hitting transparent parts of children if robust check passes
          child: Center(child: rotated),
        ),
      );
    } else {
      return Positioned(
        left: cx - (diag / 2),
        top: cy - (diag / 2),
        width: diag,
        height: diag,
        child: Center(child: rotated),
      );
    }
  }

  Color _getTableColor(int status, int defaultColor) {
    switch (status) {
      case 1: // Occupied
        return AppTheme.statusOccupied;
      case 2: // Cleaning
        return AppTheme.statusCleaning;
      case 0: // Available
      default:
        return Color(defaultColor);
    }
  }
}
