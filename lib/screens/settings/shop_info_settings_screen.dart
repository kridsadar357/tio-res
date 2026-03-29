import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:respos/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';

class ShopInfoSettingsScreen extends StatefulWidget {
  const ShopInfoSettingsScreen({super.key});

  @override
  State<ShopInfoSettingsScreen> createState() => _ShopInfoSettingsScreenState();
}

class _ShopInfoSettingsScreenState extends State<ShopInfoSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _telController;
  String _logoPath = '';
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _nameController = TextEditingController(text: settings.shopName);
    _addressController = TextEditingController(text: settings.shopAddress);
    _telController = TextEditingController(text: settings.shopTel);
    _logoPath = settings.shopLogoPath;
    _openTime = _parseTime(settings.openTime);
    _closeTime = _parseTime(settings.closeTime);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Save to app directory to avoid permission issues
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'shop_logo_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage =
            await File(image.path).copy('${appDir.path}/$fileName');

        setState(() => _logoPath = savedImage.path);
      } catch (e) {
        debugPrint('Error saving logo: $e');
        // Fallback to original path if copy fails (though less ideal)
        setState(() => _logoPath = image.path);
      }
    }
  }

  Future<void> _pickTime(bool isOpenTime) async {
    final initialTime = isOpenTime ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              surface: const Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.saveShopInfo(
      name: _nameController.text,
      address: _addressController.text,
      tel: _telController.text,
      logoPath: _logoPath,
      openTime: _formatTime(_openTime),
      closeTime: _formatTime(_closeTime),
    );
    if (mounted) {
      PremiumToast.show(
          context, AppLocalizations.of(context)!.shopInfoSavedSuccessfully);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _telController.dispose();
    super.dispose();
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
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.shopInformation,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 18),
              label: Text(l10n.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: _logoPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.file(File(_logoPath), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40.sp, color: Colors.white30),
                            SizedBox(height: 8.h),
                            Text(l10n.addLogo,
                                style: TextStyle(
                                    color: Colors.white30, fontSize: 12.sp)),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Shop Name
            _buildLabel(l10n.shopName),
            SizedBox(height: 8.h),
            _buildTextField(_nameController, l10n.enterShopName),
            SizedBox(height: 24.h),

            // Address
            _buildLabel(l10n.address),
            SizedBox(height: 8.h),
            _buildTextField(_addressController, l10n.enterAddress, maxLines: 3),
            SizedBox(height: 24.h),

            // Telephone
            _buildLabel(l10n.telephone),
            SizedBox(height: 8.h),
            _buildTextField(_telController, l10n.enterPhoneNumber,
                keyboardType: TextInputType.phone),
            SizedBox(height: 24.h),

            // Operating Hours
            _buildLabel(l10n.operatingHours),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildTimePicker(l10n.open, _openTime, true)),
                SizedBox(width: 16.w),
                Expanded(
                    child: _buildTimePicker(l10n.close, _closeTime, false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontSize: 16.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white30, fontSize: 16.sp),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isOpenTime) {
    return GestureDetector(
      onTap: () => _pickTime(isOpenTime),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                SizedBox(height: 4.h),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(Icons.access_time, color: Colors.white54, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
