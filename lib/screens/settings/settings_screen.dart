import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/premium_scaffold.dart';
import 'about_screen.dart';
import 'shop_info_settings_screen.dart';
import 'payment_settings_screen.dart';
import 'printer_settings_screen.dart';
import 'api_settings_screen.dart';
import 'backup_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
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
                  l10n.settings,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.5,
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
                // Shop Information
                _buildSectionHeader(l10n.shopInformation),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildNavSetting(
                    l10n.shopDetails,
                    settings.shopName.isNotEmpty
                        ? settings.shopName
                        : l10n.notConfigured,
                    Icons.store,
                    const ShopInfoSettingsScreen(),
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    l10n.paymentSettings,
                    settings.promptPayId.isNotEmpty
                        ? '${l10n.promptPay}: ${settings.promptPayId}'
                        : l10n.notConfigured,
                    Icons.payment,
                    const PaymentSettingsScreen(),
                  ),
                ]),
                SizedBox(height: 32.h),

                // Hardware & Integrations
                _buildSectionHeader('Hardware & Integrations'),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildNavSetting(
                    'Printer Settings',
                    'Bluetooth, Network (IP), USB',
                    Icons.print,
                    const PrinterSettingsScreen(),
                  ),
                  _buildDivider(),
                  _buildNavSetting(
                    'API Configuration',
                    'Endpoints & Keys',
                    Icons.api,
                    const ApiSettingsScreen(),
                  ),
                ]),
                SizedBox(height: 32.h),

                // Appearance
                _buildSectionHeader(l10n.appearance),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildDropdownSetting(
                    l10n.theme,
                    settings.themeMode,
                    Icons.palette,
                    {
                      'dark': l10n.dark,
                      'light': l10n.light,
                      'system': l10n.system
                    },
                    (val) => settings.setThemeMode(val),
                  ),
                  _buildDivider(),
                  _buildDropdownSetting(
                    l10n.currency,
                    settings.currency,
                    Icons.attach_money,
                    {'฿': l10n.thaiBaht, '\$': l10n.usDollar},
                    (val) => settings.setCurrency(val),
                  ),
                  _buildDivider(),
                  _buildDropdownSetting(
                    l10n.language,
                    settings.language,
                    Icons.language,
                    {'th': 'ไทย (Thai)', 'en': 'English'},
                    (val) => settings.setLanguage(val),
                  ),
                ]),
                SizedBox(height: 32.h),

                // POS Preferences
                _buildSectionHeader('POS Preferences'),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildSliderSetting(
                    'Tax Rate (%)',
                    settings.taxRate,
                    (val) => settings.setTaxRate(val),
                    min: 0,
                    max: 20,
                  ),
                  _buildDivider(),
                  _buildSliderSetting(
                    'Service Charge (%)',
                    settings.serviceCharge,
                    (val) => settings.setServiceCharge(val),
                    min: 0,
                    max: 20,
                  ),
                ]),
                SizedBox(height: 32.h),

                // General
                _buildSectionHeader('General'),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildSwitchSetting(
                    'Sound Effects',
                    settings.enableSound,
                    (val) => settings.setEnableSound(val),
                  ),
                  _buildDivider(),
                  _buildSwitchSetting(
                    'Notifications',
                    settings.enableNotifications,
                    (val) => settings.setEnableNotifications(val),
                  ),
                ]),
                SizedBox(height: 32.h),

                // Data Management
                _buildSectionHeader(l10n.backupRestore),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildNavSetting(
                    l10n.backupRestore,
                    'Export & Import data',
                    Icons.backup,
                    const BackupSettingsScreen(),
                  ),
                ]),
                SizedBox(height: 32.h),

                // App Info
                _buildSectionHeader('App Info'),
                SizedBox(height: 16.h),
                _buildSettingsCard([
                  _buildNavSettingSimple('About ResPOS', const AboutScreen()),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            letterSpacing: 1.0,
            shadows: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                blurRadius: 10,
              )
            ]),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.1));
  }

  Widget _buildNavSetting(
      String label, String subtitle, IconData icon, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute<void>(builder: (context) => destination));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon,
                  color: Theme.of(context).primaryColor, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.sp)),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildNavSettingSimple(String label, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute<void>(builder: (context) => destination));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.sp)),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String currentValue,
    IconData icon,
    Map<String, String> options,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child:
                Icon(icon, color: Theme.of(context).primaryColor, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(label,
                style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                dropdownColor: const Color(0xFF2A2A3E),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
                icon: Icon(Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20.sp),
                items: options.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
      String label, double value, void Function(double) onChanged,
      {double min = 0, double max = 100}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              Text('${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
              trackHeight: 4.h,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
      String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
