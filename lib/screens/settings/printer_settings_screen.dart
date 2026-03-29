import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/premium_scaffold.dart';
import '../bluetooth_printer_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/printer_service.dart';
import '../../services/printer/bluetooth_printer_adapter.dart';
import '../../services/printer/printer_adapter.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when connection changes
    _printerService.addListener(_onPrinterServiceChanged);
  }

  @override
  void dispose() {
    _printerService.removeListener(_onPrinterServiceChanged);
    super.dispose();
  }

  void _onPrinterServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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
              l10n.printerSettings,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(24.w),
        children: [
          // Bluetooth Printer Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const BluetoothPrinterScreen(),
                  ),
                );
                // Refresh connection status after returning
                if (mounted) {
                  setState(() {});
                }
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.bluetooth,
                        color: theme.primaryColor,
                        size: 32.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.bluetoothPrinter,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            l10n.bluetoothPrinter,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Connection Status Card
          _buildConnectionStatusCard(l10n, theme),
          
          SizedBox(height: 24.h),
          
          // Info Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Setup Instructions',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionStep(
                    '1',
                    'Pair your printer with your Android device in Bluetooth settings',
                    theme,
                  ),
                  SizedBox(height: 12.h),
                  _buildInstructionStep(
                    '2',
                    'Open Bluetooth Printer settings above',
                    theme,
                  ),
                  SizedBox(height: 12.h),
                  _buildInstructionStep(
                    '3',
                    'Select your printer from the list and connect',
                    theme,
                  ),
                  SizedBox(height: 12.h),
                  _buildInstructionStep(
                    '4',
                    'Test print to verify the connection works',
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(AppLocalizations l10n, ThemeData theme) {
    // Check actual connection status from adapter
    final adapter = _printerService.adapter;
    final serviceConnected = _printerService.isConnected;
    
    return FutureBuilder<bool>(
      future: _checkActualConnection(adapter),
      builder: (context, snapshot) {
        // Use actual connection status if available, otherwise use service status
        final isConnected = snapshot.data ?? serviceConnected;
        final btAdapter = adapter is BluetoothPrinterAdapter ? adapter : null;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isConnected 
                ? Colors.green.withValues(alpha: 0.1)
                : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isConnected 
                  ? Colors.green.withValues(alpha: 0.3)
                  : theme.dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isConnected 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isConnected ? Icons.check_circle : Icons.error_outline,
                    color: isConnected ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? l10n.connected : l10n.notConnected,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isConnected 
                            ? Colors.green 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (isConnected && btAdapter != null && btAdapter.connectedDevice != null)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            btAdapter.connectedDevice!.name ?? 
                            btAdapter.connectedDevice!.address ?? 
                            _printerService.address ?? 
                            l10n.unknownDevice,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      else if (isConnected && _printerService.address != null)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            _printerService.address!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkActualConnection(PrinterAdapter? adapter) async {
    if (adapter == null) return false;
    try {
      return await adapter.isConnected;
    } catch (e) {
      return false;
    }
  }

  Widget _buildInstructionStep(String number, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
