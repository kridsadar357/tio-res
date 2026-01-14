import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/database_helper.dart';
import '../../models/table_model.dart';
import '../../models/layout_object_model.dart';
import '../../widgets/visual_floor_plan.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/icon_helper.dart';

class LayoutDesignerScreen extends StatefulWidget {
  const LayoutDesignerScreen({super.key});

  @override
  State<LayoutDesignerScreen> createState() => _LayoutDesignerScreenState();
}

class _LayoutDesignerScreenState extends State<LayoutDesignerScreen> {
  // Grid settings
  final double gridSize = 20.0;

  List<TableModel> _tables = [];
  List<LayoutObjectModel> _objects = [];

  // Selection
  TableModel? _selectedTable;
  LayoutObjectModel? _selectedObject;

  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tables = await DatabaseHelper().getAllTables();
    final objects = await DatabaseHelper().getAllLayoutObjects();
    setState(() {
      _tables = tables;
      _objects = objects;
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Save all tables (only layout props might have changed)
      for (var table in _tables) {
        await DatabaseHelper().updateTableLayout(table);
      }

      // Save all objects
      for (var obj in _objects) {
        if (obj.id == null) {
          await DatabaseHelper().addLayoutObject(obj);
        } else {
          await DatabaseHelper().updateLayoutObject(obj);
        }
      }

      if (mounted) PremiumToast.show(context, l10n.layoutSaved);
      // Reload to get IDs for new objects
      _loadData();
    } catch (e) {
      if (mounted)
        PremiumToast.show(context, l10n.errorSavingLayout(e.toString()),
            isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PremiumScaffold(
      header: _buildHeader(l10n),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Palette - Optimized as separate widget
                Expanded(flex: 2, child: ToolsPalette(l10n: l10n)),
                // Center Canvas
                Expanded(
                  flex: 7,
                  child: RepaintBoundary(child: _buildCanvas()),
                ),
                // Right Properties
                Expanded(flex: 3, child: _buildPropertiesPanel(l10n)),
              ],
            ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            l10n.layoutDesigner,
            style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: Text(l10n.saveLayout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return VisualFloorPlan(
      tables: _tables,
      objects: _objects,
      isEditable: true,
      canvasKey: _canvasKey,
      transformationController: _transformationController,
      selectedTable: _selectedTable,
      selectedObject: _selectedObject,
      onDrop: (type, x, y) {
        if (type == 'Table') {
          _addNewTable(x, y);
        } else {
          _addNewObject(type, x, y);
        }
      },
      onTableTap: (table) => setState(() {
        _selectedTable = table;
        _selectedObject = null;
      }),
      onObjectTap: (obj) => setState(() {
        _selectedObject = obj;
        _selectedTable = null;
      }),
      onTablePanStart: (table) => setState(() {
        _selectedTable = table;
        _selectedObject = null;
      }),
      onObjectPanStart: (obj) => setState(() {
        _selectedObject = obj;
        _selectedTable = null;
      }),
      onTableDragUpdate: (table, details) {
        setState(() {
          final idx = _tables.indexWhere((t) => t.id == table.id);
          if (idx != -1) {
            // Adjust delta by current zoom scale to sync movement with cursor
            final scale = _transformationController.value.getMaxScaleOnAxis();
            double newX = table.x + (details.delta.dx / scale);
            double newY = table.y + (details.delta.dy / scale);

            // Snap to grid removed for smoothness
            // newX = (newX / gridSize).round() * gridSize;
            // newY = (newY / gridSize).round() * gridSize;

            _tables[idx] = table.copyWith(
              x: newX,
              y: newY,
            );
          }
        });
      },
      onObjectDragUpdate: (obj, details) {
        setState(() {
          final idx = _objects.indexOf(obj);
          if (idx != -1) {
            // Adjust delta by current zoom scale
            final scale = _transformationController.value.getMaxScaleOnAxis();
            double newX = obj.x + (details.delta.dx / scale);
            double newY = obj.y + (details.delta.dy / scale);

            // Snap to grid removed for smoothness
            // newX = (newX / gridSize).round() * gridSize;
            // newY = (newY / gridSize).round() * gridSize;

            _objects[idx] = obj.copyWith(
              x: newX,
              y: newY,
            );
            _selectedObject = _objects[idx];
          }
        });
      },
    );
  }

  void _addNewTable(double x, double y) async {
    final l10n = AppLocalizations.of(context)!;
    final id =
        await DatabaseHelper().addTable('${l10n.table} ${_tables.length + 1}');
    final newTable = TableModel(
      id: id,
      tableName: '${l10n.table} ${_tables.length + 1}',
      status: 0,
      x: x - 40, y: y - 40, // Center (80/2)
      width: 80, height: 80,
    );
    setState(() => _tables.add(newTable));
  }

  void _addNewObject(String type, double x, double y) {
    // Map localized type back to internal key if needed, or better, pass internal key from draggables
    // The Palette draggables pass the internal key (unlocalized logic in Palette widget)
    final width = type == 'Wall' ? 10.0 : 80.0;
    final height = type == 'Wall' ? 100.0 : 80.0;

    final newObj = LayoutObjectModel(
      type: type.toLowerCase(),
      x: x - (width / 2),
      y: y - (height / 2),
      width: width,
      height: height,
      color: Colors.grey.value,
    );
    setState(() => _objects.add(newObj));
  }

  Widget _buildPropertiesPanel(AppLocalizations l10n) {
    if (_selectedTable == null && _selectedObject == null) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
            child: Text(l10n.selectItem,
                style: const TextStyle(color: Colors.white54))),
      );
    }

    // Use centralized IconHelper
    final availableIcons = IconHelper.getAvailableIcons(l10n);

    // Simple properties for generic item
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      padding: EdgeInsets.all(16.w),
      child: ListView(
        children: [
          Text(l10n.properties,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          if (_selectedTable != null) ...[
            Text('${l10n.table}: ${_selectedTable!.tableName}',
                style: const TextStyle(color: Colors.white)),
            SizedBox(height: 10.h),
            _buildSlider(l10n.width, _selectedTable!.width, 20, 300, (val) {
              setState(() {
                final idx = _tables.indexOf(_selectedTable!);
                _tables[idx] = _selectedTable!.copyWith(width: val);
                _selectedTable = _tables[idx];
              });
            }),
            _buildSlider(l10n.height, _selectedTable!.height, 20, 300, (val) {
              setState(() {
                final idx = _tables.indexOf(_selectedTable!);
                _tables[idx] = _selectedTable!.copyWith(height: val);
                _selectedTable = _tables[idx];
              });
            }),
            _buildSlider(l10n.rotation, _selectedTable!.rotation, 0, 6.28,
                (val) {
              // Radians
              setState(() {
                final idx = _tables.indexOf(_selectedTable!);
                _tables[idx] = _selectedTable!.copyWith(rotation: val);
                _selectedTable = _tables[idx];
              });
            }),
            SizedBox(height: 10.h),
            Text(l10n.fillColor, style: const TextStyle(color: Colors.white)),
            SizedBox(height: 5.h),
            Wrap(
              spacing: 8,
              children: [
                _buildColorBtn(Colors.green, 0xFF4CAF50, true),
                _buildColorBtn(Colors.red, 0xFFF44336, true),
                _buildColorBtn(Colors.blue, 0xFF2196F3, true),
                _buildColorBtn(Colors.orange, 0xFFFF9800, true),
              ],
            )
          ] else ...[
            Text(
                '${l10n.object}: ${_getObjectName(l10n, _selectedObject!.type)}',
                style: const TextStyle(color: Colors.white)),
            SizedBox(height: 10.h),
            _buildSlider(l10n.width, _selectedObject!.width, 10, 500, (val) {
              setState(() {
                final idx = _objects.indexOf(_selectedObject!);
                _objects[idx] = _selectedObject!.copyWith(width: val);
                _selectedObject = _objects[idx];
              });
            }),
            _buildSlider(l10n.height, _selectedObject!.height, 10, 500, (val) {
              setState(() {
                final idx = _objects.indexOf(_selectedObject!);
                _objects[idx] = _selectedObject!.copyWith(height: val);
                _selectedObject = _objects[idx];
              });
            }),
            _buildSlider(l10n.rotation, _selectedObject!.rotation, 0, 6.28,
                (val) {
              setState(() {
                final idx = _objects.indexOf(_selectedObject!);
                _objects[idx] = _selectedObject!.copyWith(rotation: val);
                _selectedObject = _objects[idx];
              });
            }),
            SizedBox(height: 10.h),
            Text(l10n.fillColor, style: const TextStyle(color: Colors.white)),
            SizedBox(height: 5.h),
            Wrap(
              spacing: 8,
              children: [
                _buildColorBtn(Colors.grey, 0xFF9E9E9E, false),
                _buildColorBtn(Colors.black, 0xFF000000, false),
                _buildColorBtn(Colors.brown, 0xFF795548, false),
                _buildColorBtn(Colors.blueGrey, 0xFF607D8B, false),
              ],
            ),
            SizedBox(height: 10.h),
            Text(l10n.icon, style: const TextStyle(color: Colors.white)),
            SizedBox(height: 5.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIcons.map((iconMap) {
                final iconData = iconMap['icon'] as IconData?;
                final isSelected = (_selectedObject!.iconPoint ?? 0) ==
                    (iconData?.codePoint ?? 0);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final idx = _objects.indexOf(_selectedObject!);
                      _objects[idx] = _selectedObject!
                          .copyWith(iconPoint: iconData?.codePoint ?? 0);
                      _selectedObject = _objects[idx];
                    });
                  },
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: iconData != null
                        ? FaIcon(iconData, size: 16.sp, color: Colors.white)
                        : Icon(Icons.close, size: 16.sp, color: Colors.red),
                  ),
                );
              }).toList(),
            )
          ],
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _duplicateSelectedItem,
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.duplicate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _bringToFront,
                  style:
                      OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(l10n.toFront),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: _sendToBack,
                  style:
                      OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(l10n.toBack),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: _deleteSelectedItem,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getObjectName(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'wall':
        return l10n.wall;
      case 'plant':
        return l10n.plant;
      case 'door':
        return l10n.door;
      case 'chair':
        return l10n.chair;
      case 'couch':
        return l10n.couch;
      case 'table':
        return l10n.table;
      default:
        return type;
    }
  }

  Widget _buildSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white70)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.green,
          inactiveColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildColorBtn(Color color, int value, bool isTable) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isTable) {
            final idx = _tables.indexOf(_selectedTable!);
            _tables[idx] = _selectedTable!.copyWith(color: value);
            _selectedTable = _tables[idx];
          } else {
            final idx = _objects.indexOf(_selectedObject!);
            _objects[idx] = _selectedObject!.copyWith(color: value);
            _selectedObject = _objects[idx];
          }
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }

  void _deleteSelectedItem() {
    if (_selectedTable != null) {
      DatabaseHelper().deleteTable(_selectedTable!.id).then((_) {
        setState(() {
          _tables.remove(_selectedTable);
          _selectedTable = null;
        });
      });
    } else if (_selectedObject != null) {
      if (_selectedObject!.id != null) {
        DatabaseHelper().deleteLayoutObject(_selectedObject!.id!);
      }
      setState(() {
        _objects.remove(_selectedObject);
        _selectedObject = null;
      });
    }
  }

  void _duplicateSelectedItem() async {
    // final l10n = AppLocalizations.of(context)!; // Unused
    if (_selectedTable != null) {
      final newId =
          await DatabaseHelper().addTable('${_selectedTable!.tableName} Copy');
      final newTable = _selectedTable!.copyWith(
        id: newId,
        tableName: '${_selectedTable!.tableName} Copy',
        x: _selectedTable!.x + 20,
        y: _selectedTable!.y + 20,
      );
      setState(() {
        _tables.add(newTable);
        _selectedTable = newTable;
      });
    } else if (_selectedObject != null) {
      final newObj = _selectedObject!.copyWith(
        id: null, // Clear ID to create new
        x: _selectedObject!.x + 20,
        y: _selectedObject!.y + 20,
      );
      setState(() {
        _objects.add(newObj);
        _selectedObject = newObj;
      });
    }
  }

  void _bringToFront() {
    if (_selectedObject != null) {
      setState(() {
        _objects.remove(_selectedObject);
        _objects.add(_selectedObject!);
      });
    }
    if (_selectedTable != null) {
      setState(() {
        _tables.remove(_selectedTable);
        _tables.add(_selectedTable!);
      });
    }
  }

  void _sendToBack() {
    if (_selectedObject != null) {
      setState(() {
        _objects.remove(_selectedObject);
        _objects.insert(0, _selectedObject!);
      });
    }
    if (_selectedTable != null) {
      setState(() {
        _tables.remove(_selectedTable);
        _tables.insert(0, _selectedTable!);
      });
    }
  }
}

// Extracted Palette Widget to prevent rebuilds on Canvas drag
class ToolsPalette extends StatelessWidget {
  final AppLocalizations l10n;
  const ToolsPalette({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tools,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          _buildPaletteItem(
              'Table', l10n.table, Icons.table_restaurant, Colors.orange),
          SizedBox(height: 12.h),
          _buildPaletteItem(
              'Wall', l10n.wall, Icons.crop_landscape, Colors.grey),
          SizedBox(height: 12.h),
          _buildPaletteItem(
              'Plant', l10n.plant, Icons.local_florist, Colors.green),
          SizedBox(height: 12.h),
          _buildPaletteItem(
              'Door', l10n.door, Icons.meeting_room, Colors.blueGrey),
          SizedBox(height: 12.h),
          _buildPaletteItem('Chair', l10n.chair, Icons.chair, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildPaletteItem(
      String type, String label, IconData icon, Color color) {
    // data is 'type' which is internal key (Table, Wall, etc.)
    return Draggable<String>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 12.w),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
