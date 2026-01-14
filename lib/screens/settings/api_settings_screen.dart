import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:respos/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../theme/app_theme.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _apiEnabled = false;

  static const String _keyApiEnabled = 'api_enabled';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyApiKey = 'api_key';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiEnabled = prefs.getBool(_keyApiEnabled) ?? false;
      _baseUrlController.text = prefs.getString(_keyBaseUrl) ?? '';
      _apiKeyController.text = prefs.getString(_keyApiKey) ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyApiEnabled, _apiEnabled);
    await prefs.setString(_keyBaseUrl, _baseUrlController.text.trim());
    await prefs.setString(_keyApiKey, _apiKeyController.text.trim());

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _isLoading = false);
    if (mounted) {
      PremiumToast.show(
          context, AppLocalizations.of(context)!.apiSettingsSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 16.w),
            Text(
              l10n.apiSettings,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Toggle Card
              _buildToggleCard(),
              SizedBox(height: 24.h),

              // Configuration Card
              AnimatedOpacity(
                opacity: _apiEnabled ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_apiEnabled,
                  child: _buildConfigCard(l10n),
                ),
              ),

              SizedBox(height: 24.h),

              // Endpoints Info Card
              if (_apiEnabled) _buildEndpointsInfoCard(),

              SizedBox(height: 32.h),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.saveConfiguration,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _apiEnabled
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D2137)]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _apiEnabled
              ? AppTheme.accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: _apiEnabled ? 2 : 1,
        ),
        boxShadow: _apiEnabled
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _apiEnabled
                  ? AppTheme.accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_sync,
              size: 28.sp,
              color: _apiEnabled ? AppTheme.accent : Colors.white54,
            ),
          ),
          SizedBox(width: 16.w),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เปิดใช้งาน API',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _apiEnabled
                      ? 'ระบบจะซิงค์ข้อมูลกับเซิร์ฟเวอร์'
                      : 'ระบบทำงานแบบออฟไลน์',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: _apiEnabled,
              onChanged: (val) => setState(() => _apiEnabled = val),
              activeColor: AppTheme.accent,
              activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.endpointsConfig,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          SizedBox(height: 20.h),
          // Base URL
          _buildTextField(
            controller: _baseUrlController,
            label: 'Base URL',
            hint: 'https://yourserver.com/php-orders/api',
            icon: Icons.link,
          ),
          SizedBox(height: 16.h),
          // API Key
          _buildTextField(
            controller: _apiKeyController,
            label: l10n.apiKeyOptional,
            hint: 'Secret API Key',
            icon: Icons.vpn_key,
            isSecret: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointsInfoCard() {
    final endpoints = [
      {'name': 'get_items.php', 'desc': 'ดึงรายการเมนู', 'method': 'GET'},
      {'name': 'send_orders.php', 'desc': 'ส่งออเดอร์', 'method': 'POST'},
      {'name': 'check_bill.php', 'desc': 'เช็คบิล', 'method': 'GET'},
      {'name': 'update_items.php', 'desc': 'อัพเดทเมนู', 'method': 'PUT'},
      {'name': 'delete_items.php', 'desc': 'ลบเมนู', 'method': 'DELETE'},
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18.sp, color: Colors.white54),
              SizedBox(width: 8.w),
              Text(
                'API Endpoints',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...endpoints.map((ep) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getMethodColor(ep['method']!)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        ep['method']!,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: _getMethodColor(ep['method']!),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      ep['name']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ep['desc']!,
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSecret = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isSecret,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white70),
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
      ),
      validator: (value) {
        if (!isSecret && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล';
        }
        return null;
      },
    );
  }
}
