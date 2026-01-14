import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item.dart';
import '../../models/menu_category.dart';
import '../../services/database_helper.dart';
import '../../services/api_service.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/currency_helper.dart';

class ManageItemScreen extends StatefulWidget {
  final MenuItem? item; // null for new item

  const ManageItemScreen({super.key, this.item});

  @override
  State<ManageItemScreen> createState() => _ManageItemScreenState();
}

class _ManageItemScreenState extends State<ManageItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameThController;
  late TextEditingController _nameCnController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  int? _selectedCategoryId;
  bool _isBuffetIncluded = true;
  bool _isActive = true;
  File? _imageFile;
  bool _isLoading = false;

  final ImageStorageService _imageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _nameThController = TextEditingController(text: widget.item?.nameTh ?? '');
    _nameCnController = TextEditingController(text: widget.item?.nameCn ?? '');
    _skuController = TextEditingController(text: widget.item?.sku ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(
        text: widget.item?.price.toStringAsFixed(2) ?? '0.00');
    _selectedCategoryId = widget.item?.categoryId;
    _isBuffetIncluded = widget.item?.isBuffetIncluded ?? true;
    _isActive = widget.item?.status == 1; // Default true if null/1

    if (widget.item?.imagePath != null) {
      _loadExistingImage(widget.item!.imagePath!);
    }
  }

  Future<void> _loadExistingImage(String path) async {
    final file = await _imageService.getImageFile(path);
    if (mounted) {
      setState(() {
        _imageFile = file;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameThController.dispose();
    _nameCnController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      PremiumToast.show(context, 'Please select a category', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagePath = widget.item?.imagePath;

      // If user picked a new image
      if (_imageFile != null) {
        imagePath = await _imageService.saveImage(_imageFile!);
      }

      final item = MenuItem(
        id: widget.item?.id,
        name: _nameController.text.trim(),
        nameTh: _nameThController.text.trim(),
        nameCn: _nameCnController.text.trim(),
        sku: _skuController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imagePath: imagePath,
        isBuffetIncluded: _isBuffetIncluded,
        status: _isActive ? 1 : 0,
      );

      int itemId;
      if (widget.item == null) {
        itemId = await DatabaseHelper().addMenuItem(item);
      } else {
        await DatabaseHelper().updateMenuItem(item);
        itemId = widget.item!.id!;
      }

      // Sync to API if enabled
      final apiService = ApiService();
      if (apiService.isEnabled) {
        final savedItem = item.copyWith(id: itemId);
        await apiService.syncMenuItem(savedItem);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Error saving item: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final l10n = AppLocalizations.of(context)!;

    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  isEditing ? l10n.editItem : l10n.newItem,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.save, style: TextStyle(fontSize: 14.sp)),
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section: Image + Basic Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Image.file(_imageFile!,
                                        fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          size: 24.sp, color: Colors.white54),
                                      SizedBox(height: 4.h),
                                      Text(l10n.addImage,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.white54)),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Basic Fields
                        Expanded(
                          child: Column(
                            children: [
                              FutureBuilder<List<MenuCategory>>(
                                future: DatabaseHelper().getAllCategories(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                        height: 48,
                                        child: Center(
                                            child: LinearProgressIndicator()));
                                  }
                                  return DropdownButtonFormField<int>(
                                    initialValue: _selectedCategoryId,
                                    dropdownColor: const Color(
                                        0xFF252836), // Dark dropdown
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14.sp),
                                    decoration:
                                        _inputDecoration(l10n.categoryLabel),
                                    items: snapshot.data!.map((c) {
                                      return DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedCategoryId = val);
                                    },
                                    validator: (val) => val == null
                                        ? l10n.pleaseSelectCategory
                                        : null,
                                  );
                                },
                              ),
                              SizedBox(height: 12.h),
                              TextFormField(
                                controller: _skuController,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14.sp),
                                decoration: _inputDecoration(l10n.codeSku),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Language Section
                    Text(l10n.namesSection,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      decoration: _inputDecoration(l10n.englishName,
                          icon: Icons.language),
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.pleaseEnterName
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameThController,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.sp),
                            decoration: _inputDecoration(l10n.thaiName),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            controller: _nameCnController,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.sp),
                            decoration: _inputDecoration(l10n.chineseName),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Pricing & Details
                    Text(l10n.pricingDetails,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.sp),
                            decoration: _inputDecoration(l10n.price,
                                prefix: '${CurrencyHelper.symbol(context)} '),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF252836), // Match input fill
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: Theme.of(context).primaryColor,
                              title: Text(l10n.buffetIncluded,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(l10n.priceZeroForBuffet,
                                  style: TextStyle(
                                      fontSize: 11.sp, color: Colors.white54)),
                              value: _isBuffetIncluded,
                              onChanged: (val) {
                                setState(() => _isBuffetIncluded = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      decoration: _inputDecoration(l10n.description),
                    ),
                    SizedBox(height: 16.h),

                    // Status
                    Container(
                      decoration: BoxDecoration(
                        color: _isActive
                            ? const Color(0xFF252836)
                            : const Color(0xFF252836),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _isActive
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.red.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: SwitchListTile(
                        dense: true,
                        title: Text(l10n.availableActive,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: _isActive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(l10n.markAsSoldOut,
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.white54)),
                        activeThumbColor: Colors.greenAccent,
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ),
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label,
      {IconData? icon, String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70, fontSize: 13.sp),
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.white54, size: 18.sp) : null,
      prefixText: prefix,
      prefixStyle: TextStyle(
          color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: const Color(0xFF252836), // Darker surface
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      isDense: true,
    );
  }
}
