import 'dart:io';
import 'package:flutter/material.dart';
import 'package:respos/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/edc_service.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../theme/app_theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  late TextEditingController _promptPayIdController;
  String _qrPath = '';

  // EDC Settings
  final EdcService _edcService = EdcService();
  late bool _edcEnabled;
  late EdcTerminalType _edcTerminalType;
  late EdcConnectionType _edcConnectionType;
  late TextEditingController _edcAddressController;
  late TextEditingController _edcTerminalIdController;
  late TextEditingController _edcMerchantIdController;
  bool _testingConnection = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _promptPayIdController = TextEditingController(text: settings.promptPayId);
    _qrPath = settings.promptPayQrPath;

    // EDC Settings
    _edcEnabled = _edcService.isEnabled;
    _edcTerminalType = _edcService.terminalType;
    _edcConnectionType = _edcService.connectionType;
    _edcAddressController = TextEditingController(text: _edcService.address);
    _edcTerminalIdController =
        TextEditingController(text: _edcService.terminalId);
    _edcMerchantIdController =
        TextEditingController(text: _edcService.merchantId);
  }

  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _qrPath = image.path);
    }
  }

  Future<void> _save() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Save PromptPay settings
    await settings.savePaymentSettings(
      promptPayId: _promptPayIdController.text,
      promptPayQrPath: _qrPath,
    );

    // Save EDC settings
    await _edcService.saveSettings(
      enabled: _edcEnabled,
      terminalType: _edcTerminalType,
      connectionType: _edcConnectionType,
      address: _edcAddressController.text.trim(),
      terminalId: _edcTerminalIdController.text.trim(),
      merchantId: _edcMerchantIdController.text.trim(),
    );

    if (mounted) {
      PremiumToast.show(context,
          AppLocalizations.of(context)!.paymentSettingsSavedSuccessfully);
      Navigator.pop(context);
    }
  }

  Future<void> _testEdcConnection() async {
    setState(() => _testingConnection = true);

    final success = await _edcService.testConnection();

    setState(() => _testingConnection = false);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      PremiumToast.show(
        context,
        success ? l10n.connectionSuccess : l10n.connectionFailed,
        isError: !success,
      );
    }
  }

  @override
  void dispose() {
    _promptPayIdController.dispose();
    _edcAddressController.dispose();
    _edcTerminalIdController.dispose();
    _edcMerchantIdController.dispose();
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
              l10n.paymentSettings,
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
            // PromptPay Section
            _buildPromptPaySection(l10n),
            SizedBox(height: 24.h),

            // EDC Section
            _buildEdcSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptPaySection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.qr_code, color: Colors.blue, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.promptPay,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // PromptPay ID
          Text(
            l10n.promptPayId,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _promptPayIdController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            decoration: _inputDecoration(l10n.promptPayIdHint),
          ),
          SizedBox(height: 24.h),

          // QR Code Image
          Text(
            l10n.qrCodeImage,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          Center(
            child: GestureDetector(
              onTap: _pickQrImage,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: _qrPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Image.file(File(_qrPath), fit: BoxFit.contain),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48.sp, color: Colors.grey),
                          SizedBox(height: 8.h),
                          Text(
                            l10n.tapToUploadQr,
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14.sp),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdcSection(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _edcEnabled
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D2137)]
              : [
                  Colors.grey.shade800.withValues(alpha: 0.5),
                  Colors.grey.shade900.withValues(alpha: 0.5)
                ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _edcEnabled
              ? AppTheme.accent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Toggle
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _edcEnabled
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: _edcEnabled ? Colors.green : Colors.grey,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.edcPayment,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.edcDescription,
                      style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _edcEnabled,
                onChanged: (val) => setState(() => _edcEnabled = val),
                activeColor: Colors.green,
              ),
            ],
          ),

          if (_edcEnabled) ...[
            SizedBox(height: 24.h),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            SizedBox(height: 16.h),

            // Terminal Type
            Text(l10n.terminalType,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EdcTerminalType>(
                  value: _edcTerminalType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E2A3A),
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  items: EdcTerminalType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(EdcService.getTerminalTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _edcTerminalType = val!),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Connection Type
            Text(l10n.connectionType,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EdcConnectionType>(
                  value: _edcConnectionType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E2A3A),
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  items: EdcConnectionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(EdcService.getConnectionTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _edcConnectionType = val!),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Terminal Address
            Text(l10n.terminalAddress,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            TextField(
              controller: _edcAddressController,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: _inputDecoration(
                _edcConnectionType == EdcConnectionType.network
                    ? l10n.addressHintNetwork
                    : l10n.addressHintSerial,
              ),
            ),
            SizedBox(height: 16.h),

            // Terminal ID & Merchant ID
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.terminalId,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _edcTerminalIdController,
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        decoration: _inputDecoration('TID'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.merchantId,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _edcMerchantIdController,
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        decoration: _inputDecoration('MID'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testingConnection ? null : _testEdcConnection,
                icon: _testingConnection
                    ? SizedBox(
                        width: 18.sp,
                        height: 18.sp,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white70),
                      )
                    : Icon(Icons.cable, size: 18.sp),
                label: Text(l10n.testConnection),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
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
    );
  }
}
