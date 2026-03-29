import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';
import '../models/table_model.dart';
import '../models/layout_object_model.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';
import 'transformable_box.dart';

class VisualFloorPlan extends StatelessWidget {
  final List<TableModel> tables;
  final List<LayoutObjectModel> objects;
  final void Function(TableModel)? onTableTap;
  final void Function(LayoutObjectModel)? onObjectTap;
  final bool isEditable;
  final void Function(String, double, double)? onDrop; // type, x, y
  final TransformationController? transformationController;
  final GlobalKey? canvasKey;
  // Drag update callbacks
  final void Function(TableModel, DragUpdateDetails)? onTableDragUpdate;
  final void Function(LayoutObjectModel, DragUpdateDetails)? onObjectDragUpdate;
  final void Function(TableModel)? onTablePanStart;
  final void Function(LayoutObjectModel)? onObjectPanStart;
  
  // New callbacks for geometry changes
  final void Function(TableModel, double width, double height)? onTableResize;
  final void Function(LayoutObjectModel, double width, double height)? onObjectResize;
  final void Function(TableModel, double angle)? onTableRotate;
  final void Function(LayoutObjectModel, double angle)? onObjectRotate;

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
    this.onTableResize,
    this.onObjectResize,
    this.onTableRotate,
    this.onObjectRotate,
    this.selectedTable,
    this.selectedObject,
  });

  @override
  Widget build(BuildContext context) {
    const double canvasWidth = 2000.0;
    const double canvasHeight = 1500.0;
    
    // Get current scale to keep handles separate size
    // Note: If this doesn't rebuild on zoom, handles will shrink/grow. 
    // Ideally parent should rebuild this widget on zoom change if perfect handle size is needed.
    // For now we assume scale 1.0 or whatever is passed implicitly via controller value if we accessed it.
    // We can try to peek at the controller value if available.
    double currentScale = 1.0;
    if (transformationController != null) {
      currentScale = transformationController!.value.getMaxScaleOnAxis();
    }

    // Pre-build children lists to avoid recreating on every build
    final objectWidgets = List<Widget>.generate(
      objects.length,
      (index) => _buildObject(context, objects[index], currentScale),
    );
    final tableWidgets = List<Widget>.generate(
      tables.length,
      (index) => _buildTable(context, tables[index], currentScale),
    );

    return RepaintBoundary(
      child: Container(
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
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
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
                    ...objectWidgets,
                    ...tableWidgets,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, TableModel table, double scale) {
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Center(
        child: Text(table.tableName,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
    );

    if (isEditable) {
      return Positioned(
        left: table.x,
        top: table.y,
        child: TransformableBox(
          isSelected: isSelected,
          width: table.width,
          height: table.height,
          rotation: table.rotation,
          currentScale: scale,
          onTap: () => onTableTap?.call(table),
          onDrag: (delta) {
            // We need to construct a pseudo drag details
             onTableDragUpdate?.call(table, DragUpdateDetails(
               delta: delta, 
               globalPosition: Offset.zero,
             ));
          },
          onResize: (w, h) => onTableResize?.call(table, w, h),
          onRotate: (angle) => onTableRotate?.call(table, table.rotation + angle),
          child: content,
        ),
      );
    } else {
      // Logic for non-editable mode remains mostly same
      Widget rotated = Transform.rotate(
        angle: table.rotation,
        child: content,
      );
      
      return Positioned(
        left: table.x,
        top: table.y,
        child: GestureDetector(
          onTap: () => onTableTap?.call(table),
          child: rotated,
        ),
      );
    }
  }

  Widget _buildObject(BuildContext context, LayoutObjectModel obj, double scale) {
    final isSelected = selectedObject == obj;

    // 1. Visual Content
    Widget visualContent = Container(
      width: obj.width,
      height: obj.height,
      decoration: BoxDecoration(
        color: obj.color != null ? Color(obj.color!) : Colors.grey,
      ),
      child: (obj.iconPoint != null && obj.iconPoint != 0)
          ? Center(
              child: FaIcon(
                IconHelper.getIconByCodePoint(obj.iconPoint) ??
                    const IconData(0xe000, fontFamily: 'MaterialIcons'),
                color: Theme.of(context).colorScheme.onSurface,
                size: min(obj.width, obj.height) * 0.6,
              ),
            )
          : obj.type == 'plant'
              ? const Icon(Icons.local_florist, color: Colors.green)
              : null,
    );

    if (isEditable) {
      return Positioned(
        left: obj.x,
        top: obj.y,
        child: TransformableBox(
          isSelected: isSelected,
          width: obj.width,
          height: obj.height,
          rotation: obj.rotation,
          currentScale: scale,
          onTap: () => onObjectTap?.call(obj),
           onDrag: (delta) {
             onObjectDragUpdate?.call(obj, DragUpdateDetails(
               delta: delta, 
               globalPosition: Offset.zero, 
              ));
          },
          onResize: (w, h) => onObjectResize?.call(obj, w, h),
          onRotate: (angle) => onObjectRotate?.call(obj, obj.rotation + angle),
          child: visualContent,
        ),
      );
    } else {
      Widget rotated = Transform.rotate(
        angle: obj.rotation,
        child: visualContent,
      );
      
       return Positioned(
        left: obj.x,
        top: obj.y,
        child: GestureDetector(
          onTap: () => onObjectTap?.call(obj),
          child: rotated,
        ),
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
