import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../models/receipt_layout.dart';
import '../../widgets/premium_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/currency_helper.dart';
import '../../providers/settings_provider.dart';

class VisualReceiptDesignerScreen extends StatefulWidget {
  const VisualReceiptDesignerScreen({super.key});

  @override
  State<VisualReceiptDesignerScreen> createState() =>
      _VisualReceiptDesignerScreenState();
}

class _VisualReceiptDesignerScreenState
    extends State<VisualReceiptDesignerScreen> {
  late ReceiptLayout _layout;
  String? _selectedComponentId;
  String _currentLayoutType = 'checkout'; // 'checkout' or 'opentable'

  static const String _keyCheckout = 'receipt_layout_config';
  static const String _keyOpenTable = 'receipt_layout_opentable';

  String get _currentPrefsKey =>
      _currentLayoutType == 'checkout' ? _keyCheckout : _keyOpenTable;

  @override
  void initState() {
    super.initState();
    _layout = ReceiptLayout.defaultLayout();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_currentPrefsKey);
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        var layout = ReceiptLayout.fromJson(jsonMap);

        // Check for duplicate IDs and fix them
        final ids = <String>{};
        bool hasDuplicates = false;
        final newComponents = <ReceiptComponent>[];

        for (final component in layout.components) {
          if (ids.contains(component.id)) {
            hasDuplicates = true;
            // Generate a new unique ID
            final newId =
                '${DateTime.now().microsecondsSinceEpoch}_${newComponents.length}';
            newComponents.add(ReceiptComponent(
              id: newId,
              type: component.type,
              data: component.data,
              style: component.style,
            ));
            ids.add(newId);
          } else {
            ids.add(component.id);
            newComponents.add(component);
          }
        }

        if (hasDuplicates) {
          debugPrint('Duplicate IDs found in receipt layout. Fixing...');
          layout = layout.copyWith(components: newComponents);
          // Save the fixed layout immediately
          final fixedJsonString = jsonEncode(layout.toJson());
          await prefs.setString(_currentPrefsKey, fixedJsonString);
        }

        setState(() {
          _layout = layout;
        });
      }
    } catch (e) {
      debugPrint('Error loading receipt layout: $e');
      // If error (e.g. format change), reset to default
      setState(() {
        _layout = ReceiptLayout.defaultLayout();
      });
    }
  }

  Future<void> _saveLayout() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_layout.toJson());
      await prefs.setString(_currentPrefsKey, jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.layoutSaved),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.errorSavingLayout(e.toString())),
              backgroundColor: Colors.red),
        );
      }
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.visualReceiptDesignerTitle,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  _buildPaperSizeButton(58),
                  _buildPaperSizeButton(80),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Layout Type Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  _buildLayoutTypeButton('checkout', 'Checkout'),
                  _buildLayoutTypeButton('opentable', 'Open Table'),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            ElevatedButton.icon(
              onPressed: () {
                _saveLayout();
              },
              icon: const Icon(Icons.save),
              label: Text(l10n.saveLayout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 240.w,
            child: _buildPalette(),
          ),
          Expanded(
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SingleChildScrollView(
                child: _buildCanvas(),
              ),
            ),
          ),
          SizedBox(
            width: 300.w,
            child: _buildPropertiesPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeButton(int size) {
    final isSelected = _layout.paperSizeMm == size;
    return GestureDetector(
      onTap: () {
        setState(() {
          _layout = _layout.copyWith(paperSizeMm: size);
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          '${size}mm',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutTypeButton(String type, String label) {
    final isSelected = _currentLayoutType == type;
    return GestureDetector(
      onTap: () async {
        if (isSelected) return;
        // Optionally save current before switching?
        // _saveLayout();

        setState(() {
          _currentLayoutType = type;
          _selectedComponentId = null;
        });
        await _loadLayout();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPalette() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(l10n.componentsTitle,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: Colors.white)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                // Store Info Section
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text('Store Info',
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold)),
                ),
                _buildDraggableItem(ReceiptComponentType.shopLogo, Icons.image,
                    'Shop Logo'),
                _buildDraggableItem(ReceiptComponentType.shopName, Icons.storefront,
                    'Shop Name'),
                _buildDraggableItem(ReceiptComponentType.shopAddress, Icons.location_on,
                    'Shop Address'),
                _buildDraggableItem(ReceiptComponentType.shopTel, Icons.phone,
                    'Shop Tel'),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                ),
                // Basic Components Section
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text('Basic Components',
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold)),
                ),
                _buildDraggableItem(ReceiptComponentType.header, Icons.store,
                    l10n.headerComponent),
                _buildDraggableItem(ReceiptComponentType.text,
                    Icons.text_fields, l10n.textComponent),
                _buildDraggableItem(ReceiptComponentType.divider,
                    Icons.horizontal_rule, l10n.dividerComponent),
                _buildDraggableItem(ReceiptComponentType.space, Icons.space_bar,
                    l10n.spacerComponent),
                _buildDraggableItem(ReceiptComponentType.image, Icons.image,
                    l10n.imageComponent),
                _buildDraggableItem(
                    ReceiptComponentType.qrcode, Icons.qr_code, 'QR Code'),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                ),
                // Dynamic Data Section
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(l10n.dynamicData,
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold)),
                ),
                _buildDraggableItem(ReceiptComponentType.dynamicItems,
                    Icons.list_alt, l10n.orderListComponent),
                _buildDraggableItem(ReceiptComponentType.dynamicTotal,
                    Icons.summarize, l10n.totalsComponent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(
      ReceiptComponentType type, IconData icon, String label) {
    return Draggable<ReceiptComponentType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(12.w),
          width: 200.w,
          decoration: BoxDecoration(
            color: const Color(0xFF252836),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: Colors.white70),
            SizedBox(width: 12.w),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    final l10n = AppLocalizations.of(context)!;
    final width = _layout.paperSizeMm == 80 ? 380.w : 280.w;

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: 500.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: DragTarget<ReceiptComponentType>(
        onAcceptWithDetails: (details) {
          setState(() {
            _layout.components.add(ReceiptComponent.create(details.data));
            _selectedComponentId = _layout.components.last.id;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _layout.components.removeAt(oldIndex);
                _layout.components.insert(newIndex, item);
              });
            },
            children: [
              for (int index = 0; index < _layout.components.length; index++)
                _buildCanvasItem(index, _layout.components[index]),
              if (candidateData.isNotEmpty)
                Container(
                  key: const ValueKey('placeholder'),
                  height: 50,
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Center(
                      child: Text(l10n.dropHere,
                          style: const TextStyle(color: Colors.blue))),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCanvasItem(int index, ReceiptComponent component) {
    final isSelected = component.id == _selectedComponentId;

    return ReorderableDragStartListener(
      key: ValueKey(component.id),
      index: index,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedComponentId = component.id;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : Border.all(color: Colors.transparent),
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSelected)
                  Center(
                      child: Icon(Icons.drag_indicator,
                          size: 16.sp, color: Colors.grey)),
                Expanded(
                  child: AbsorbPointer(
                    child: _renderComponentPreview(component),
                  ),
                ),
                if (isSelected)
                  Center(
                    child: IconButton(
                      icon:
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _layout.components.removeAt(index);
                          if (_selectedComponentId == component.id) {
                            _selectedComponentId = null;
                          }
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderComponentPreview(ReceiptComponent component) {
    final align = _getAlignment(component.style['alignment'] as String?);
    final double fontSize = ((component.style['fontSize'] as num?) ?? 14).toDouble();
    final bool isBold = (component.style['bold'] as bool?) == true;

    switch (component.type) {
      case ReceiptComponentType.header:
      case ReceiptComponentType.text:
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text(
            (component.data['text'] as String?) ?? '',
            textAlign: _getTextAlign(component.style['alignment'] as String?),
            style: TextStyle(
              fontSize: ScreenUtil().setSp(fontSize),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
              color: Colors.black,
            ),
          ),
        );
      case ReceiptComponentType.divider:
        return Container(
          alignment: Alignment.center,
          child: Text(
            '-' * 32,
            style: const TextStyle(fontFamily: 'Courier', color: Colors.black),
          ),
        );
      case ReceiptComponentType.image:
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              Icon(Icons.image, size: 48.sp, color: Colors.grey.shade400),
              SizedBox(height: 4.h),
              Text('[Image]',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
            ],
          ),
        );
      case ReceiptComponentType.qrcode:
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              Icon(Icons.qr_code, size: 48.sp, color: Colors.black),
              SizedBox(height: 4.h),
              Text((component.data['payload'] as String?) ?? 'QR Code',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            ],
          ),
        );
      case ReceiptComponentType.space:
        return SizedBox(
            height: ScreenUtil()
                .setHeight(((component.style['height'] as num?) ?? 20).toDouble()));
      case ReceiptComponentType.dynamicItems:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          color: Colors.grey.shade100,
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item A',
                      style: TextStyle(
                          fontFamily: 'Courier', color: Colors.black)),
                  Text('1 x 10.00',
                      style: TextStyle(
                          fontFamily: 'Courier', color: Colors.black)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item B',
                      style: TextStyle(
                          fontFamily: 'Courier', color: Colors.black)),
                  Text('2 x 5.00',
                      style: TextStyle(
                          fontFamily: 'Courier', color: Colors.black)),
                ],
              ),
            ],
          ),
        );
      case ReceiptComponentType.dynamicTotal:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          alignment: Alignment.centerRight,
          child: Text(
            'Total: ${CurrencyHelper.symbol(context)} 20.00',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                fontSize: 16,
                color: Colors.black),
          ),
        );
      case ReceiptComponentType.shopLogo:
        final settings = context.read<SettingsProvider>();
        final logoPath = settings.shopLogoPath;
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: logoPath.isNotEmpty && File(logoPath).existsSync()
              ? Image.file(
                  File(logoPath),
                  width: 100.w,
                  height: 60.h,
                  fit: BoxFit.contain,
                )
              : Column(
                  children: [
                    Icon(Icons.image, size: 48.sp, color: Colors.grey.shade400),
                    SizedBox(height: 4.h),
                    Text('[Shop Logo]',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
                  ],
                ),
        );
      case ReceiptComponentType.shopName:
        final settings = context.read<SettingsProvider>();
        final shopName = settings.shopName.isNotEmpty ? settings.shopName : 'Shop Name';
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text(
            shopName,
            textAlign: _getTextAlign(component.style['alignment'] as String?),
            style: TextStyle(
              fontSize: ScreenUtil().setSp(fontSize),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
              color: Colors.black,
            ),
          ),
        );
      case ReceiptComponentType.shopAddress:
        final settings = context.read<SettingsProvider>();
        final shopAddress = settings.shopAddress.isNotEmpty ? settings.shopAddress : 'Shop Address';
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Text(
            shopAddress,
            textAlign: _getTextAlign(component.style['alignment'] as String?),
            style: TextStyle(
              fontSize: ScreenUtil().setSp(fontSize),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
              color: Colors.black,
            ),
          ),
        );
      case ReceiptComponentType.shopTel:
        final settings = context.read<SettingsProvider>();
        final shopTel = settings.shopTel.isNotEmpty ? 'Tel: ${settings.shopTel}' : 'Tel: 000-000-0000';
        return Container(
          alignment: align,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Text(
            shopTel,
            textAlign: _getTextAlign(component.style['alignment'] as String?),
            style: TextStyle(
              fontSize: ScreenUtil().setSp(fontSize),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
              color: Colors.black,
            ),
          ),
        );
      default:
        return SizedBox(
            height: 20.h,
            child: const Center(
                child: Text('Unknown Component',
                    style: TextStyle(color: Colors.black))));
    }
  }

  Alignment _getAlignment(String? align) {
    switch (align) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  TextAlign _getTextAlign(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Widget _buildPropertiesPanel() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedComponentId == null) {
      return Container(
          color: Theme.of(context).cardTheme.color,
          child: Center(
              child: Text(l10n.selectElementToEdit,
                  style: TextStyle(color: Colors.white54, fontSize: 16.sp))));
    }

    final index =
        _layout.components.indexWhere((c) => c.id == _selectedComponentId);
    if (index == -1) return const SizedBox.shrink();

    final component = _layout.components[index];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.propertiesTitle,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: Colors.white)),
          SizedBox(height: 24.h),
          if (component.type == ReceiptComponentType.text ||
              component.type == ReceiptComponentType.header ||
              component.type == ReceiptComponentType.shopName ||
              component.type == ReceiptComponentType.shopAddress ||
              component.type == ReceiptComponentType.shopTel) ...[
            Text(l10n.alignmentLabel,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  _buildAlignButton(
                      component, 'left', Icons.format_align_left, index),
                  _buildAlignButton(
                      component, 'center', Icons.format_align_center, index),
                  _buildAlignButton(
                      component, 'right', Icons.format_align_right, index),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Only show text content field for editable text components
            // Shop info components get content from settings automatically
            if (component.type == ReceiptComponentType.text ||
                component.type == ReceiptComponentType.header) ...[
              Text(l10n.textContentLabel,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
              SizedBox(height: 8.h),
              TextFormField(
                key: ValueKey('${component.id}_text'),
                initialValue: component.data['text'] as String?,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none),
                    isDense: true),
                maxLines: 2,
                onChanged: (val) {
                  setState(() {
                    component.data['text'] = val;
                  });
                },
              ),
              SizedBox(height: 24.h),
            ],
            // Show info message for shop info components
            if (component.type == ReceiptComponentType.shopName ||
                component.type == ReceiptComponentType.shopAddress ||
                component.type == ReceiptComponentType.shopTel) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Content from Settings > Shop Info',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
            Text(l10n.fontSizeLabel,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            Slider(
              value: ((component.style['fontSize'] as num?) ?? 14).toDouble(),
              min: 10,
              max: 40,
              divisions: 30,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.white10,
              label: (component.style['fontSize'] as num?)?.toString() ?? '14',
              onChanged: (val) {
                setState(() {
                  component.style['fontSize'] = val.toInt();
                });
              },
            ),
          ],
          if (component.type == ReceiptComponentType.space) ...[
            Text(l10n.heightLabel,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            Slider(
              value: ((component.style['height'] as num?) ?? 20).toDouble(),
              min: 5,
              max: 100,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.white10,
              onChanged: (val) {
                setState(() {
                  component.style['height'] = val.toInt();
                });
              },
            ),
          ],
          if (component.type == ReceiptComponentType.qrcode) ...[
            Text(l10n.alignmentLabel,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  _buildAlignButton(
                      component, 'left', Icons.format_align_left, index),
                  _buildAlignButton(
                      component, 'center', Icons.format_align_center, index),
                  _buildAlignButton(
                      component, 'right', Icons.format_align_right, index),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text('Size (Low to High)',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            Slider(
              value: ((component.style['size'] as num?) ?? 6).toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.white10,
              label: component.style['size'].toString(),
              onChanged: (val) {
                setState(() {
                  component.style['size'] = val.toInt();
                });
              },
            ),
          ],
          if (component.type == ReceiptComponentType.shopLogo ||
              component.type == ReceiptComponentType.image) ...[
            Text(l10n.alignmentLabel,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  _buildAlignButton(
                      component, 'left', Icons.format_align_left, index),
                  _buildAlignButton(
                      component, 'center', Icons.format_align_center, index),
                  _buildAlignButton(
                      component, 'right', Icons.format_align_right, index),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text('Width',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70)),
            Slider(
              value: ((component.style['width'] as num?) ?? 150).toDouble(),
              min: 50,
              max: 300,
              divisions: 25,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.white10,
              label: '${((component.style['width'] as num?) ?? 150).toInt()}px',
              onChanged: (val) {
                setState(() {
                  component.style['width'] = val.toInt();
                });
              },
            ),
            SizedBox(height: 12.h),
            // Info for shop logo
            if (component.type == ReceiptComponentType.shopLogo)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Logo from Settings > Shop Info',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlignButton(
      ReceiptComponent component, String align, IconData icon, int index) {
    final isSelected = (component.style['alignment'] ?? 'left') == align;
    return Expanded(
      child: IconButton(
        icon: Icon(icon,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.white54),
        onPressed: () {
          setState(() {
            component.style['alignment'] = align;
          });
        },
      ),
    );
  }
}
