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

  // Track deletions for batch save
  final List<int> _deletedTableIds = [];
  final List<int> _deletedObjectIds = [];

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
      _deletedTableIds.clear();
      _deletedObjectIds.clear();
      // Clear selection to avoid stale references causing RangeError
      _selectedTable = null;
      _selectedObject = null;
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Use batch save for atomic operation
      await DatabaseHelper().saveLayoutBatch(
        tables: _tables,
        objects: _objects,
        deletedTableIds: _deletedTableIds,
        deletedObjectIds: _deletedObjectIds,
      );

      if (mounted) PremiumToast.show(context, l10n.layoutSaved);
      // Reload to reflect changes and get new IDs
      _loadData();
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, l10n.errorSavingLayout(e.toString()),
            isError: true);
      }
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
            l10n.layoutDesigner,
            style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface),
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
      onTablePanStart: (table) {
        FocusScope.of(context).unfocus();
        setState(() {
          _selectedTable = table;
          _selectedObject = null;
        });
      },
      onObjectPanStart: (obj) {
        FocusScope.of(context).unfocus();
        setState(() {
          _selectedObject = obj;
          _selectedTable = null;
        });
      },
      onTableDragUpdate: (table, details) {
        setState(() {
          final idx = _tables.indexWhere((t) => t.id == table.id);
          if (idx != -1) {
            // Adjust delta by current zoom scale to sync movement with cursor
            final scale = _transformationController.value.getMaxScaleOnAxis();
            double newX = table.x + (details.delta.dx / scale);
            double newY = table.y + (details.delta.dy / scale);

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
            final scale = _transformationController.value.getMaxScaleOnAxis();
            double newX = obj.x + (details.delta.dx / scale);
            double newY = obj.y + (details.delta.dy / scale);

            _objects[idx] = obj.copyWith(
              x: newX,
              y: newY,
            );
            _selectedObject = _objects[idx];
          }
        });
      },
      // New Geometry Callbacks
      onTableResize: (table, w, h) {
        setState(() {
           final idx = _tables.indexWhere((t) => t.id == table.id);
           if (idx != -1) {
             _tables[idx] = table.copyWith(width: w, height: h);
             _selectedTable = _tables[idx];
           }
        });
      },
      onObjectResize: (obj, w, h) {
        setState(() {
           final idx = _objects.indexOf(obj);
           if (idx != -1) {
             _objects[idx] = obj.copyWith(width: w, height: h);
             _selectedObject = _objects[idx];
           }
        });
      },
      onTableRotate: (table, angle) {
         setState(() {
           final idx = _tables.indexWhere((t) => t.id == table.id);
           if (idx != -1) {
             _tables[idx] = table.copyWith(rotation: angle);
             _selectedTable = _tables[idx];
           }
        });
      },
      onObjectRotate: (obj, angle) {
        setState(() {
           final idx = _objects.indexOf(obj);
           if (idx != -1) {
             _objects[idx] = obj.copyWith(rotation: angle);
             _selectedObject = _objects[idx];
           }
        });
      },
    );
  }

  void _addNewTable(double x, double y) async {
    final l10n = AppLocalizations.of(context)!;
    // For batch save, new tables need a temporary negative ID or similar if we wanted to avoid immediate DB insert.
    // However, DatabaseHelper.addTable returns an int ID.
    // To be consistent with "Save" button philosophy, we should ideally NOT insert yet.
    // But `TableModel` usually expects an ID.
    // Compromise: We insert immediately for Tables (since they are more strict entities), or we handle null/temp ID.
    // Existing code did immediate insert.
    // If we want to fix "missing original", maybe we should just rely on the batch helper for *updates*.
    // But `saveLayoutBatch` handles inserts for objects.
    // Let's defer table insert too? `TableModel` id is `int`. If we make it nullable or allow 0/negative?
    // `TableModel` definition: `final int id;` (required).
    // Changing `TableModel` is risky.
    // Let's stick to immediate insert for Tables for now (as before), but batch update for positions.
    // ACTUALLY, checking `_addNewObject` logic: it creates `LayoutObjectModel` with null ID.
    // `TableModel` ID is required.
    // I'll keep `_addNewTable` as is (immediate insert). But `_addNewObject` is fine with batch.
    
    final id = await DatabaseHelper().addTable('${l10n.table} ${_tables.length + 1}');
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
    final width = type == 'Wall' ? 10.0 : 80.0;
    final height = type == 'Wall' ? 100.0 : 80.0;

    final newObj = LayoutObjectModel(
      type: type.toLowerCase(),
      x: x - (width / 2),
      y: y - (height / 2),
      width: width,
      height: height,
      color: 0xFF9E9E9E,
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
            // Width/Height controls removed or kept as fine-tuning?
            // Keeping them as "Fine Tuning"
            _PropertyInput(
              label: l10n.width,
              value: _selectedTable!.width,
              onChanged: (val) {
                setState(() {
                  final idx = _tables.indexWhere((t) => t.id == _selectedTable!.id);
                  if (idx != -1) {
                    _tables[idx] = _selectedTable!.copyWith(width: val);
                    _selectedTable = _tables[idx];
                  }
                });
              },
            ),
            SizedBox(height: 10.h),
            _PropertyInput(
              label: l10n.height,
              value: _selectedTable!.height,
              onChanged: (val) {
                setState(() {
                  final idx = _tables.indexWhere((t) => t.id == _selectedTable!.id);
                  if (idx != -1) {
                    _tables[idx] = _selectedTable!.copyWith(height: val);
                    _selectedTable = _tables[idx];
                  }
                });
              },
            ),
            _buildSlider(l10n.rotation, _selectedTable!.rotation, 0, 6.28,
                (val) {
              // Radians
              setState(() {
                final idx = _tables.indexWhere((t) => t.id == _selectedTable!.id);
                if (idx != -1) {
                  _tables[idx] = _selectedTable!.copyWith(rotation: val);
                  _selectedTable = _tables[idx];
                }
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
            _PropertyInput(
              label: l10n.width,
              value: _selectedObject!.width,
              onChanged: (val) {
                setState(() {
                  final idx = _objects.indexOf(_selectedObject!);
                  if (idx != -1) {
                    _objects[idx] = _selectedObject!.copyWith(width: val);
                    _selectedObject = _objects[idx];
                  }
                });
              },
            ),
            SizedBox(height: 10.h),
            _PropertyInput(
              label: l10n.height,
              value: _selectedObject!.height,
              onChanged: (val) {
                setState(() {
                  final idx = _objects.indexOf(_selectedObject!);
                  if (idx != -1) {
                    _objects[idx] = _selectedObject!.copyWith(height: val);
                    _selectedObject = _objects[idx];
                  }
                });
              },
            ),
            _buildSlider(l10n.rotation, _selectedObject!.rotation, 0, 6.28,
                (val) {
              setState(() {
                final idx = _objects.indexOf(_selectedObject!);
                if (idx != -1) {
                  _objects[idx] = _selectedObject!.copyWith(rotation: val);
                  _selectedObject = _objects[idx];
                }
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
                      if (idx != -1) {
                        _objects[idx] = _selectedObject!
                            .copyWith(iconPoint: iconData?.codePoint ?? 0);
                        _selectedObject = _objects[idx];
                      }
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
      void Function(double) onChanged) {
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
            final idx = _tables.indexWhere((t) => t.id == _selectedTable!.id);
            if (idx != -1) {
              _tables[idx] = _selectedTable!.copyWith(color: value);
              _selectedTable = _tables[idx];
            }
          } else {
            final idx = _objects.indexOf(_selectedObject!);
            if (idx != -1) {
              _objects[idx] = _selectedObject!.copyWith(color: value);
              _selectedObject = _objects[idx];
            }
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
      // For tables, we might defer to save, but table IDs are strict.
      // If we immediately delete from DB, we can't 'Cancel'.
      // But we are in "Designer" mode where "Save" suggests commit.
      // Let's defer delete.
      setState(() {
          _deletedTableIds.add(_selectedTable!.id);
          _tables.remove(_selectedTable);
          _selectedTable = null;
      });
    } else if (_selectedObject != null) {
      if (_selectedObject!.id != null) {
         setState(() {
            _deletedObjectIds.add(_selectedObject!.id!);
            _objects.remove(_selectedObject);
            _selectedObject = null;
         });
      } else {
        // Not in DB yet
        setState(() {
          _objects.remove(_selectedObject);
          _selectedObject = null;
        });
      }
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

class _PropertyInput extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PropertyInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PropertyInput> createState() => _PropertyInputState();
}

class _PropertyInputState extends State<_PropertyInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // on blur, reset text to current formatted value (cleans up partial inputs)
        _controller.text = widget.value.toStringAsFixed(1);
      }
    });
  }

  @override
  void didUpdateWidget(_PropertyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text validation if NOT focused (user is not typing)
    if (!_focusNode.hasFocus &&
        (widget.value - double.parse(_controller.text)).abs() > 0.1) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.white70)),
        SizedBox(height: 4.h),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h)),
          onChanged: (val) {
            final d = double.tryParse(val);
            if (d != null) widget.onChanged(d);
          },
        ),
      ],
    );
  }
}
