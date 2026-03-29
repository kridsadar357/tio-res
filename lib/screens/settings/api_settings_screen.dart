import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:respos/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/menu_translations.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _qrBaseUrlController = TextEditingController();
  
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _apiEnabled = false;
  bool _qrOrderEnabled = false;
  bool _isSyncing = false;
  bool _showApiKey = false;
  String _syncStatus = '';
  FullSyncResult? _lastSyncResult;
  bool _connectionTested = false;
  bool _connectionSuccess = false;

  static const String _keyApiEnabled = 'api_enabled';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyApiKey = 'api_key';
  static const String _keyQrOrderEnabled = 'qr_order_enabled';
  static const String _keyQrBaseUrl = 'qr_base_url';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _qrBaseUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiEnabled = prefs.getBool(_keyApiEnabled) ?? false;
      _baseUrlController.text = prefs.getString(_keyBaseUrl) ?? '';
      _apiKeyController.text = prefs.getString(_keyApiKey) ?? '';
      _qrOrderEnabled = prefs.getBool(_keyQrOrderEnabled) ?? false;
      _qrBaseUrlController.text = prefs.getString(_keyQrBaseUrl) ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyApiEnabled, _apiEnabled);
    await prefs.setString(_keyBaseUrl, _baseUrlController.text.trim());
    await prefs.setString(_keyApiKey, _apiKeyController.text.trim());
    await prefs.setBool(_keyQrOrderEnabled, _qrOrderEnabled);
    await prefs.setString(_keyQrBaseUrl, _qrBaseUrlController.text.trim());
    await ApiService().init();
    setState(() => _isLoading = false);
    if (mounted) {
      PremiumToast.show(context, AppLocalizations.of(context)!.apiSettingsSaved);
    }
  }

  Future<void> _testConnection() async {
    await _saveSettings();
    if (!_apiEnabled || _baseUrlController.text.isEmpty) {
      PremiumToast.show(context, AppLocalizations.of(context)!.apiNotEnabled);
      return;
    }

    setState(() {
      _connectionTested = false;
      _isLoading = true;
    });

    final api = ApiService();
    final connected = await api.testConnection();

    setState(() {
      _connectionTested = true;
      _connectionSuccess = connected;
      _isLoading = false;
    });

    if (mounted) {
      PremiumToast.show(
        context,
        connected 
            ? 'เชื่อมต่อสำเร็จ ✓' 
            : AppLocalizations.of(context)!.apiConnectionFailed,
      );
    }
  }

  Future<void> _syncAllData() async {
    await _saveSettings();
    if (!_apiEnabled || _baseUrlController.text.isEmpty) {
      PremiumToast.show(context, AppLocalizations.of(context)!.apiNotEnabled);
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncStatus = 'กำลังเชื่อมต่อ...';
      _lastSyncResult = null;
    });

    final api = ApiService();
    final connected = await api.testConnection();
    if (!connected) {
      setState(() {
        _isSyncing = false;
        _syncStatus = '';
      });
      if (mounted) {
        PremiumToast.show(context, AppLocalizations.of(context)!.apiConnectionFailed);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storeInfo = <String, dynamic>{
      'name': prefs.getString('shop_name') ?? '',
      'name_th': prefs.getString('shop_name') ?? '',
      'address': prefs.getString('shop_address') ?? '',
      'tel': prefs.getString('shop_tel') ?? '',
      'currency': prefs.getString('currency') ?? 'THB',
      'tax_rate': prefs.getDouble('tax_rate') ?? 7.0,
      'promptpay_id': prefs.getString('promptpay_id') ?? '',
    };
    storeInfo.removeWhere((key, value) => value == '' || value == null);

    final result = await api.syncAllData(
      storeInfo: storeInfo.isNotEmpty ? storeInfo : null,
      onProgress: (status) {
        if (mounted) setState(() => _syncStatus = status);
      },
    );

    setState(() {
      _isSyncing = false;
      _syncStatus = '';
      _lastSyncResult = result;
    });

    if (mounted) {
      PremiumToast.show(
        context,
        result.success 
            ? AppLocalizations.of(context)!.apiSyncSuccess 
            : AppLocalizations.of(context)!.apiSyncPartialFail,
      );
    }
  }

  Future<void> _applyTranslations() async {
    setState(() => _isSyncing = true);
    
    try {
      final count = await applyMenuTranslations();
      if (mounted) {
        PremiumToast.show(context, 'Translated $count items (EN/CN)');
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PremiumScaffold(
      header: _buildHeader(l10n),
      body: Column(
        children: [
          // Master Toggle + Status Bar
          _buildStatusBar(l10n),
          
          // Tab Bar
          _buildTabBar(l10n),
          
          // Tab Content
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConnectionTab(l10n, isDark),
                  _buildSyncTab(l10n, isDark),
                  _buildQrTab(l10n, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.api, size: 28.sp, color: AppTheme.accent),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.apiSettings,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Web Ordering & Data Sync',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white54),
                ),
              ],
            ),
          ),
          // Save Button
          _buildSaveButton(l10n),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: _isLoading ? null : _saveSettings,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 16.w, height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(Icons.save, size: 18.sp, color: Colors.white),
                SizedBox(width: 6.w),
                Text(l10n.save, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _apiEnabled
              ? [const Color(0xFF1A3A5C), const Color(0xFF0D2137)]
              : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _apiEnabled ? AppTheme.accent.withValues(alpha: 0.5) : Colors.white12,
          width: _apiEnabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _apiEnabled 
                  ? (_connectionSuccess ? Colors.green : AppTheme.accent).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _apiEnabled 
                  ? (_connectionTested 
                      ? (_connectionSuccess ? Icons.cloud_done : Icons.cloud_off)
                      : Icons.cloud_queue)
                  : Icons.cloud_off,
              size: 22.sp,
              color: _apiEnabled 
                  ? (_connectionSuccess ? Colors.green : AppTheme.accent)
                  : Colors.white38,
            ),
          ),
          SizedBox(width: 12.w),
          
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _apiEnabled ? 'API เปิดใช้งาน' : 'API ปิดอยู่',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _apiEnabled ? Colors.white : Colors.white60,
                  ),
                ),
                if (_apiEnabled && _connectionTested)
                  Text(
                    _connectionSuccess ? 'เชื่อมต่อสำเร็จ' : 'ไม่สามารถเชื่อมต่อได้',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _connectionSuccess ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
              ],
            ),
          ),
          
          // Toggle
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: _apiEnabled,
              onChanged: (val) => setState(() {
                _apiEnabled = val;
                _connectionTested = false;
              }),
              activeColor: AppTheme.accent,
              activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(8.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(4.w),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            height: 44.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 16.sp),
                SizedBox(width: 6.w),
                const Text('Connection'),
              ],
            ),
          ),
          Tab(
            height: 44.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync, size: 16.sp),
                SizedBox(width: 6.w),
                const Text('Sync'),
              ],
            ),
          ),
          Tab(
            height: 44.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, size: 16.sp),
                SizedBox(width: 6.w),
                const Text('QR Order'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTab(AppLocalizations l10n, bool isDark) {
    return AnimatedOpacity(
      opacity: _apiEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_apiEnabled,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL & Key Section
              _buildSectionCard(
                title: 'Server Configuration',
                icon: Icons.dns,
                color: AppTheme.accent,
                child: Column(
                  children: [
                    _buildCompactTextField(
                      controller: _baseUrlController,
                      label: 'Base URL',
                      hint: 'https://your-domain.com',
                      icon: Icons.language,
                      suffix: Text('/api', style: TextStyle(fontSize: 12.sp, color: Colors.white38)),
                    ),
                    SizedBox(height: 12.h),
                    _buildCompactTextField(
                      controller: _apiKeyController,
                      label: 'API Key',
                      hint: 'Your secret API key',
                      icon: Icons.key,
                      isSecret: !_showApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility, size: 20.sp),
                        onPressed: () => setState(() => _showApiKey = !_showApiKey),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Test Connection Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: AppTheme.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  icon: _isLoading
                      ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.wifi_tethering, size: 20.sp),
                  label: Text('Test Connection', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Endpoints Info (Compact)
              _buildEndpointsCompact(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncTab(AppLocalizations l10n, bool isDark) {
    return AnimatedOpacity(
      opacity: _apiEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_apiEnabled,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: _buildSectionCard(
            title: l10n.syncAllData,
            icon: Icons.cloud_upload,
            color: Colors.purple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.syncAllDataDesc,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white60),
                ),
                SizedBox(height: 16.h),
                
                // Data Types Grid
                _buildSyncDataGrid(l10n),
                
                SizedBox(height: 20.h),
                
                // Sync Status
                if (_isSyncing || _syncStatus.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(10.w),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        if (_isSyncing)
                          SizedBox(
                            width: 16.w, height: 16.w,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.purple),
                          ),
                        if (_isSyncing) SizedBox(width: 10.w),
                        Expanded(
                          child: Text(_syncStatus, style: TextStyle(fontSize: 12.sp, color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                
                // Sync Results
                if (_lastSyncResult != null) _buildSyncResultsCompact(),
                
                // Sync Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    icon: _isSyncing
                        ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.sync, size: 20.sp),
                    label: Text(
                      _isSyncing ? l10n.syncing : l10n.sendAllData,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Fix Translations Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _applyTranslations,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    icon: Icon(Icons.translate, size: 20.sp, color: Colors.orange),
                    label: Text(
                      'Fix Translations (EN/CN)',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrTab(AppLocalizations l10n, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // QR Toggle Card
          _buildSectionCard(
            title: l10n.qrCodeOrdering,
            icon: Icons.qr_code_scanner,
            color: Colors.green,
            headerWidget: Switch(
              value: _qrOrderEnabled,
              onChanged: (val) => setState(() => _qrOrderEnabled = val),
              activeColor: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _qrOrderEnabled ? l10n.qrOrderingEnabled : l10n.qrOrderingDisabled,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white60),
                ),
                
                if (_qrOrderEnabled) ...[
                  SizedBox(height: 16.h),
                  _buildCompactTextField(
                    controller: _qrBaseUrlController,
                    label: l10n.qrBaseUrl,
                    hint: 'https://your-ordering-site.com',
                    icon: Icons.link,
                  ),
                  SizedBox(height: 16.h),
                  _buildQrUrlExamples(l10n),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    Widget? headerWidget,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 20.sp, color: color),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              if (headerWidget != null) headerWidget,
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSecret = false,
    Widget? suffix,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 14.sp, color: Colors.white),
      obscureText: isSecret,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.sp),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.white30),
        prefixIcon: Icon(icon, size: 20.sp, color: Colors.white54),
        suffix: suffix,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppTheme.accent),
        ),
      ),
    );
  }

  Widget _buildEndpointsCompact() {
    final endpoints = [
      {'method': 'GET', 'name': 'items', 'color': Colors.green},
      {'method': 'POST', 'name': 'orders', 'color': Colors.blue},
      {'method': 'GET', 'name': 'bill', 'color': Colors.green},
      {'method': 'PUT', 'name': 'update', 'color': Colors.orange},
      {'method': 'POST', 'name': 'sync/*', 'color': Colors.purple},
    ];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, size: 14.sp, color: Colors.white38),
              SizedBox(width: 6.w),
              Text('API Endpoints', style: TextStyle(fontSize: 11.sp, color: Colors.white54, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: endpoints.map((ep) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (ep['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ep['method'] as String,
                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: ep['color'] as Color),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '/api/${ep['name']}',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white60, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDataGrid(AppLocalizations l10n) {
    final items = [
      {'icon': Icons.store, 'name': l10n.storeInfo, 'color': Colors.purple},
      {'icon': Icons.category, 'name': l10n.categories, 'color': Colors.orange},
      {'icon': Icons.restaurant_menu, 'name': l10n.buffetTiers, 'color': Colors.red},
      {'icon': Icons.table_restaurant, 'name': l10n.tables, 'color': Colors.blue},
      {'icon': Icons.fastfood, 'name': l10n.menuItems, 'color': Colors.green},
      {'icon': Icons.image, 'name': 'Images', 'color': Colors.teal},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
      childAspectRatio: 2.2,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: (item['color'] as Color).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: (item['color'] as Color).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, size: 14.sp, color: item['color'] as Color),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  item['name'] as String,
                  style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSyncResultsCompact() {
    final result = _lastSyncResult!;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: (result.success ? Colors.green : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: (result.success ? Colors.green : Colors.orange).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.warning,
            color: result.success ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.success ? 'Sync Complete' : 'Partial Success',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: result.success ? Colors.green : Colors.orange),
                ),
                Text(
                  '${result.totalSynced} items synced',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, size: 18.sp, color: Colors.white38),
            onPressed: () => _showSyncDetailsDialog(result),
          ),
        ],
      ),
    );
  }

  void _showSyncDetailsDialog(FullSyncResult result) {
    final items = [
      {'name': 'Store Info', 'result': result.storeInfo},
      {'name': 'Categories', 'result': result.categories},
      {'name': 'Buffet Tiers', 'result': result.buffetTiers},
      {'name': 'Tables', 'result': result.tables},
      {'name': 'Menu Items', 'result': result.menuItems},
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppTheme.accent, size: 24.sp),
            SizedBox(width: 10.w),
            const Text('Sync Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final r = item['result'] as SyncResult;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Icon(r.success ? Icons.check_circle : Icons.error, size: 16.sp, color: r.success ? Colors.green : Colors.red),
                  SizedBox(width: 10.w),
                  Expanded(child: Text(item['name'] as String, style: TextStyle(fontSize: 13.sp))),
                  Text('${r.count}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white70)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrUrlExamples(AppLocalizations l10n) {
    final baseUrl = _qrBaseUrlController.text.isNotEmpty ? _qrBaseUrlController.text : 'https://example.com';
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14.sp, color: Colors.white38),
              SizedBox(width: 6.w),
              Text(l10n.qrUrlStructure, style: TextStyle(fontSize: 11.sp, color: Colors.white54, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 10.h),
          _buildUrlExample(l10n.openTableQrDesc, '$baseUrl/open-table/1'),
          SizedBox(height: 8.h),
          _buildUrlExample(l10n.menuPageDesc, '$baseUrl/?table=1'),
        ],
      ),
    );
  }

  Widget _buildUrlExample(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: url));
            PremiumToast.show(context, 'URL copied');
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(fontSize: 10.sp, color: Colors.green.shade300, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.copy, size: 14.sp, color: Colors.white38),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
