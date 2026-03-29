import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as bt;
import '../services/printer_service.dart';
import '../services/printer/bluetooth_printer_adapter.dart';
import '../widgets/premium_scaffold.dart';
import '../l10n/app_localizations.dart';

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  final PrinterService _printerService = PrinterService();
  final BluetoothPrinterAdapter _scanAdapter = BluetoothPrinterAdapter();
  
  List<bt.BluetoothDevice> _devices = [];
  List<bt.BluetoothDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  String? _errorMessage;

  BluetoothPrinterAdapter? get _adapter {
    final adapter = _printerService.adapter;
    if (adapter is BluetoothPrinterAdapter) {
      return adapter;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _checkConnection();
  }

  @override
  void dispose() {
    if (_isDiscovering) {
      _stopDiscovery();
    }
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final adapter = _adapter;
    if (adapter != null) {
      await adapter.isConnected;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final hasPermissions = await _scanAdapter.checkPermissions();
      if (!hasPermissions) {
        setState(() {
          _errorMessage = 'Bluetooth permissions are required. Please grant permissions in app settings.';
          _isScanning = false;
        });
        return;
      }

      final printer = bt.BlueThermalPrinter.instance;
      final isAvailable = await printer.isAvailable;
      
      if (isAvailable != true) {
        setState(() {
          _errorMessage = 'Bluetooth is not available. Please enable Bluetooth on your device.';
          _isScanning = false;
        });
        return;
      }

      final devices = await _scanAdapter.scanDevices();
      
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading devices: $e';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices = [];
      _errorMessage = null;
    });

    try {
      final started = await _scanAdapter.startDiscovery();
      if (!started) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isDiscovering = false;
          _errorMessage = l10n.connectionFailed;
        });
        return;
      }

      _pollDiscoveredDevices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = 'Error loading devices: $e';
        });
      }
    }
  }

  Future<void> _pollDiscoveredDevices() async {
    int pollCount = 0;
    while (_isDiscovering && mounted && pollCount < 15) {
      await Future<void>.delayed(const Duration(seconds: 1));
      pollCount++;
      try {
        final discovered = await _scanAdapter.getDiscoveredDevices();
        if (mounted) {
          setState(() {
            _discoveredDevices = discovered;
          });
        }
      } catch (e) {
        debugPrint('Error polling discovered devices: $e');
      }
    }
    if (_isDiscovering && mounted) {
      await _stopDiscovery();
    }
  }

  Future<void> _stopDiscovery() async {
    await _scanAdapter.stopDiscovery();
    if (mounted) {
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<void> _connectToDevice(bt.BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      if (_isDiscovering) {
        await _stopDiscovery();
      }

      await _printerService.saveSettings(
        PrinterType.bluetooth,
        device.address ?? '',
      );

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      
      final adapter = _adapter;
      final isConnected = adapter != null ? await adapter.isConnected : false;
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });

        if (isConnected) {
          await _loadDevices();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppLocalizations.of(context)!.connected} - ${device.name ?? device.address}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          final bondedDevices = await _scanAdapter.scanDevices();
          final isNowPaired = bondedDevices.any((d) => d.address == device.address);
          
          if (mounted) {
            setState(() {
              _errorMessage = isNowPaired
                ? 'Device is paired but connection failed. Please try connecting again.'
                : 'Connection failed. Please make sure:\n1. Printer is turned on and in range\n2. You accepted the pairing request if it appeared\n3. Try connecting again';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isConnecting = false;
          _errorMessage = '${l10n.connectionFailed}: $e';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.disconnect),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _testPrint() async {
    final success = await _printerService.printTest();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '${AppLocalizations.of(context)!.testPrint} ${AppLocalizations.of(context)!.connectionSuccess}!' 
            : '${AppLocalizations.of(context)!.testPrint} ${AppLocalizations.of(context)!.connectionFailed}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testOpenTablePrint() async {
    final success = await _printerService.printTestOpenTable();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Open Table Test Print ${AppLocalizations.of(context)!.connectionSuccess}!' 
            : 'Open Table Test Print ${AppLocalizations.of(context)!.connectionFailed}'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openBluetoothSettings() async {
    try {
      final printer = bt.BlueThermalPrinter.instance;
      await printer.openSettings;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Open Bluetooth Settings'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      debugPrint('Error opening Bluetooth settings: $e');
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bluetoothPrinter,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Connect to receipt printer',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              onPressed: _openBluetoothSettings,
              tooltip: 'Open Bluetooth Settings',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection Status Card
          _buildConnectionStatusCard(l10n, theme),
          
          // Error Message
          if (_errorMessage != null) _buildErrorMessage(theme),
          
          // Device List Header
          _buildDeviceListHeader(l10n, theme),
          
          // Device List
          Expanded(
            child: (_devices.isEmpty && _discoveredDevices.isEmpty && !_isDiscovering)
              ? _buildEmptyState(l10n, theme)
              : _buildDeviceList(l10n, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(AppLocalizations l10n, ThemeData theme) {
    return FutureBuilder<bool>(
      future: _adapter?.isConnected ?? Future.value(false),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        final connectedDevice = _adapter?.connectedDevice;
        
        return Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isConnected 
              ? Colors.green.withValues(alpha: 0.15) 
              : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isConnected 
                ? Colors.green 
                : theme.dividerColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isConnected 
                    ? Colors.green.withValues(alpha: 0.2) 
                    : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.check_circle : Icons.error_outline,
                  color: isConnected ? Colors.green : Colors.grey,
                  size: 32.sp,
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
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isConnected && connectedDevice != null)
                      Text(
                        connectedDevice.name ?? connectedDevice.address ?? l10n.unknownDevice,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (isConnected) ...[
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _disconnect,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.disconnect),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: _testPrint,
                  icon: const Icon(Icons.print, size: 18),
                  label: Text(l10n.testPrint),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: _testOpenTablePrint,
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Test Open Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red[800],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListHeader(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.bluetoothPrinter,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  if (_isDiscovering)
                    ElevatedButton.icon(
                      onPressed: _stopDiscovery,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _startDiscovery,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Scan for New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: _isScanning 
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        )
                      : Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                    onPressed: _isScanning ? null : _loadDevices,
                    tooltip: l10n.refreshList,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isDiscovering)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.scanning,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 80.sp,
              color: theme.primaryColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: 24.h),
            Text(
              _isScanning ? l10n.scanning : l10n.noDevicesFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.primaryColor, size: 24.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'How to connect your printer:',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionStep('1', 'Put your printer in pairing mode (check printer manual)', theme),
                  SizedBox(height: 12.h),
                  _buildInstructionStep('2', 'Open Android Bluetooth Settings', theme),
                  SizedBox(height: 12.h),
                  _buildInstructionStep('3', 'Find and pair your printer name', theme),
                  SizedBox(height: 12.h),
                  _buildInstructionStep('4', 'Return to this app and tap Refresh', theme),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _openBluetoothSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Bluetooth Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(AppLocalizations l10n, ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        // Paired Devices Section
        if (_devices.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'Paired Devices',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ..._devices.map((device) => _buildDeviceTile(device, true, l10n, theme)),
        ],
        
        // Discovered Devices Section
        if (_discoveredDevices.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'Nearby Devices (Tap to Pair & Connect)',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          ..._discoveredDevices.map((device) => _buildDeviceTile(device, false, l10n, theme)),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(bt.BluetoothDevice device, bool isPaired, AppLocalizations l10n, ThemeData theme) {
    final isCurrentDevice = _adapter?.connectedDevice?.address == device.address;
    
    return FutureBuilder<bool?>(
      future: bt.BlueThermalPrinter.instance.isDeviceConnected(device),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isConnected 
                  ? Colors.green.withValues(alpha: 0.1)
                  : (isPaired 
                    ? Colors.grey.withValues(alpha: 0.1)
                    : theme.primaryColor.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected 
                  ? Icons.bluetooth_connected 
                  : (isPaired 
                    ? Icons.bluetooth 
                    : Icons.bluetooth_searching),
                color: isConnected 
                  ? Colors.green 
                  : (isPaired 
                    ? Colors.grey 
                    : theme.primaryColor),
                size: 28.sp,
              ),
            ),
            title: Text(
              device.name ?? l10n.unknownDevice,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.address ?? l10n.noAddress,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isConnected)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        l10n.connected,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!isPaired)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        'Not paired - Tap to pair & connect',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing: _isConnecting && isCurrentDevice
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor,
                  ),
                )
              : ElevatedButton(
                  onPressed: _isConnecting 
                    ? null 
                    : isConnected 
                      ? _disconnect 
                      : () => _connectToDevice(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.red : theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    isConnected ? l10n.disconnect : l10n.connect,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
          ),
        );
      },
    );
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
