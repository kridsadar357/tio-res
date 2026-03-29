import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backup_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/premium_scaffold.dart';
import '../../widgets/premium_toast.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final BackupService _backupService = BackupService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<File> _availableBackups = [];
  
  @override
  void initState() {
    super.initState();
    _loadBackups();
  }
  
  Future<void> _loadBackups() async {
    final backups = await _backupService.listBackups();
    if (mounted) {
      setState(() {
        _availableBackups = backups;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      final backupPath = await _backupService.createBackup(
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
            });
          }
        },
      );
      
      if (backupPath != null && mounted) {
        PremiumToast.show(
          context,
          'Backup created: ${backupPath.split('/').last}',
        );
        await _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          'Backup failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _restoreBackup(String? filePath) async {
    // If no path provided, open file picker
    String? backupPath = filePath;
    
    if (backupPath == null) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return;
      }
      
      backupPath = result.files.first.path;
    }
    
    if (backupPath == null) return;
    
    // Confirm restore
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Restore Backup',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will replace all current data with the backup data.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 12.h),
            Text(
              'Current data will be lost!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              'The app will need to restart after restore.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });
    
    try {
      // Close database connection
      await DatabaseHelper().close();
      
      await _backupService.restoreBackup(
        backupPath,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
            });
          }
        },
      );
      
      if (mounted) {
        // Show success dialog with restart prompt
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                SizedBox(width: 12.w),
                Text(
                  'Restore Complete',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            content: Text(
              'Please restart the app to complete the restore process.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Exit app (user needs to manually restart)
                  exit(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close App'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumToast.show(
          context,
          'Restore failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return PremiumScaffold(
      header: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
              l10n.backupRestore,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          l10n.backupDescription,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Backup Section
                _buildSectionHeader(l10n.createBackup),
                SizedBox(height: 16.h),
                _buildCard([
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupIncludes,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildIncludeItem(Icons.storage, l10n.database),
                        _buildIncludeItem(Icons.image, l10n.menuImages),
                        _buildIncludeItem(Icons.settings, l10n.appSettings),
                        _buildIncludeItem(Icons.receipt_long, l10n.receiptLayouts),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createBackup,
                            icon: Icon(Icons.backup, size: 20.sp),
                            label: Text(l10n.createBackupNow),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                SizedBox(height: 32.h),
                
                // Restore Section
                _buildSectionHeader(l10n.restoreBackup),
                SizedBox(height: 16.h),
                _buildCard([
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectBackupFile,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : () => _restoreBackup(null),
                            icon: Icon(Icons.folder_open, size: 20.sp),
                            label: Text(l10n.browseFiles),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.primaryColor),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                SizedBox(height: 32.h),
                
                // Available Backups
                if (_availableBackups.isNotEmpty) ...[
                  _buildSectionHeader(l10n.availableBackups),
                  SizedBox(height: 16.h),
                  _buildCard([
                    ..._availableBackups.map((file) {
                      final stat = file.statSync();
                      final filename = file.path.split('/').last.split('\\').last;
                      return InkWell(
                        onTap: _isLoading ? null : () => _restoreBackup(file.path),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.backup,
                                  color: theme.primaryColor,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      filename,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${_formatDate(stat.modified)} • ${_formatFileSize(stat.size)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.restore,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ]),
                ],
                
                // Warning
                SizedBox(height: 32.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          l10n.backupWarning,
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        _statusMessage.isEmpty ? 'Please wait...' : _statusMessage,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16.sp,
                        ),
                        textAlign: TextAlign.center,
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
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildIncludeItem(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.green),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

