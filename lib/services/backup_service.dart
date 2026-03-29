import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import '../core/constants/app_constants.dart';

/// BackupService: Handles backup and restore of database and resources
///
/// Backup includes:
/// - SQLite database
/// - Menu images
/// - SharedPreferences settings
/// - Receipt layouts
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Backup file extension
  static const String backupExtension = '.respos';
  
  /// Backup metadata filename
  static const String metadataFilename = 'backup_metadata.json';
  
  /// Settings filename in backup
  static const String settingsFilename = 'settings.json';
  
  /// Directory names
  static const String _imagesDir = 'menu_images';
  static const String _shopImagesDir = 'shop_images';

  /// Create a full backup of all data
  /// Returns the path to the created backup file
  Future<String?> createBackup({
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Preparing backup...');
      
      final archive = Archive();
      final now = DateTime.now();
      final backupName = 'respos_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      
      // 1. Add metadata
      onProgress?.call('Creating metadata...');
      final metadata = {
        'version': AppConstants.databaseVersion,
        'createdAt': now.toIso8601String(),
        'appName': 'ResPOS',
        'platform': Platform.operatingSystem,
      };
      archive.addFile(ArchiveFile(
        metadataFilename,
        utf8.encode(jsonEncode(metadata)).length,
        utf8.encode(jsonEncode(metadata)),
      ));
      
      // 2. Add database
      onProgress?.call('Backing up database...');
      final dbPath = await sqflite.getDatabasesPath();
      final dbFile = File(path.join(dbPath, AppConstants.databaseName));
      if (await dbFile.exists()) {
        final dbBytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile(
          AppConstants.databaseName,
          dbBytes.length,
          dbBytes,
        ));
      }
      
      // 3. Add SharedPreferences (settings)
      onProgress?.call('Backing up settings...');
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = <String, dynamic>{};
      
      // Get all keys and their values
      final keys = prefs.getKeys();
      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          settingsMap[key] = {
            'type': _getValueType(value),
            'value': value,
          };
        }
      }
      
      archive.addFile(ArchiveFile(
        settingsFilename,
        utf8.encode(jsonEncode(settingsMap)).length,
        utf8.encode(jsonEncode(settingsMap)),
      ));
      
      // 4. Add menu images
      onProgress?.call('Backing up images...');
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/$_imagesDir');
      if (await imagesDir.exists()) {
        await for (final entity in imagesDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst('${appDir.path}/', '');
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(
              relativePath,
              bytes.length,
              bytes,
            ));
          }
        }
      }
      
      // 5. Add shop images (logo, etc.)
      final shopImagesDir = Directory('${appDir.path}/$_shopImagesDir');
      if (await shopImagesDir.exists()) {
        await for (final entity in shopImagesDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst('${appDir.path}/', '');
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(
              relativePath,
              bytes.length,
              bytes,
            ));
          }
        }
      }
      
      // Also backup shop logo if stored elsewhere
      final shopLogoPath = prefs.getString('shop_logo_path');
      if (shopLogoPath != null && shopLogoPath.isNotEmpty) {
        final logoFile = File(shopLogoPath);
        if (await logoFile.exists()) {
          final bytes = await logoFile.readAsBytes();
          archive.addFile(ArchiveFile(
            'shop_logo${path.extension(shopLogoPath)}',
            bytes.length,
            bytes,
          ));
        }
      }
      
      // 6. Encode archive to ZIP
      onProgress?.call('Compressing backup...');
      final zipData = ZipEncoder().encode(archive);
      
      if (zipData == null) {
        throw Exception('Failed to encode backup archive');
      }
      
      // 7. Save to downloads/external storage
      onProgress?.call('Saving backup file...');
      final downloadDir = await _getDownloadDirectory();
      final backupFile = File('${downloadDir.path}/$backupName$backupExtension');
      await backupFile.writeAsBytes(zipData);
      
      onProgress?.call('Backup complete!');
      return backupFile.path;
      
    } catch (e) {
      debugPrint('Backup error: $e');
      rethrow;
    }
  }

  /// Restore from a backup file
  Future<bool> restoreBackup(
    String backupFilePath, {
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Reading backup file...');
      
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 1. Verify metadata
      onProgress?.call('Verifying backup...');
      final metadataFile = archive.findFile(metadataFilename);
      if (metadataFile == null) {
        throw Exception('Invalid backup file: missing metadata');
      }
      
      final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>));
      debugPrint('Restoring backup from: ${metadata['createdAt']}');
      debugPrint('Backup version: ${metadata['version']}');
      
      // 2. Close current database connection
      onProgress?.call('Preparing to restore...');
      // Note: The database connection should be closed before restore
      // This is handled by the caller
      
      
      // 3. Restore database
      onProgress?.call('Restoring database...');
      final dbFile = archive.findFile(AppConstants.databaseName);
      if (dbFile != null) {
        final dbPath = await sqflite.getDatabasesPath();
        final targetDbFile = File(path.join(dbPath, AppConstants.databaseName));
        final walFile = File(path.join(dbPath, '${AppConstants.databaseName}-wal'));
        final shmFile = File(path.join(dbPath, '${AppConstants.databaseName}-shm'));
        
        // Delete existing database patterns (db, wal, shm)
        if (await targetDbFile.exists()) await targetDbFile.delete();
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();
        
        // Write restored database
        await targetDbFile.writeAsBytes(dbFile.content as List<int>);
      }
      
      // 4. Restore settings
      onProgress?.call('Restoring settings...');
      final settingsFile = archive.findFile(settingsFilename);
      if (settingsFile != null) {
        final settingsJson = utf8.decode(settingsFile.content as List<int>);
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        
        final prefs = await SharedPreferences.getInstance();
        
        for (final entry in settingsMap.entries) {
          final key = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final type = data['type'] as String;
          final value = data['value'];
          
          switch (type) {
            case 'String':
              await prefs.setString(key, value as String);
              break;
            case 'int':
              await prefs.setInt(key, value as int);
              break;
            case 'double':
              await prefs.setDouble(key, (value as num).toDouble());
              break;
            case 'bool':
              await prefs.setBool(key, value as bool);
              break;
            case 'List<String>':
              await prefs.setStringList(key, List<String>.from(value as List));
              break;
          }
        }
      }
      
      // 5. Restore images
      onProgress?.call('Restoring images...');
      final appDir = await getApplicationDocumentsDirectory();
      
      for (final file in archive.files) {
        final filename = file.name;
        
        // Skip metadata and settings files
        if (filename == metadataFilename || filename == settingsFilename || filename == AppConstants.databaseName) {
          continue;
        }
        
        // Restore image files
        if (filename.startsWith(_imagesDir) || filename.startsWith(_shopImagesDir) || filename.startsWith('shop_logo')) {
          final targetFile = File('${appDir.path}/$filename');
          
          // Create directory if needed
          final dir = targetFile.parent;
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          
          await targetFile.writeAsBytes(file.content as List<int>);
        }
      }
      
      onProgress?.call('Restore complete! Please restart the app.');
      return true;
      
    } catch (e) {
      debugPrint('Restore error: $e');
      rethrow;
    }
  }

  /// Get the download directory for saving backups
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Download folder
        final downloadDir = Directory('${externalDir.parent.parent.parent.parent.path}/Download');
        if (await downloadDir.exists()) {
          return downloadDir;
        }
      }
      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      // Windows, Linux, macOS
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${docsDir.path}/ResPOS_Backups');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    }
  }

  /// Get value type as string for serialization
  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List<String>) return 'List<String>';
    return 'unknown';
  }

  /// Get backup file info
  Future<Map<String, dynamic>?> getBackupInfo(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) return null;
      
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final metadataFile = archive.findFile(metadataFilename);
      if (metadataFile == null) return null;
      
      final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>)) as Map<String, dynamic>;
      
      // Add file info
      metadata['fileSize'] = await backupFile.length();
      metadata['filePath'] = backupFilePath;
      
      // Count files in backup
      metadata['fileCount'] = archive.files.length;
      
      return metadata;
    } catch (e) {
      debugPrint('Error reading backup info: $e');
      return null;
    }
  }
  
  /// List available backups in download directory
  Future<List<File>> listBackups() async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final backups = <File>[];
      
      await for (final entity in downloadDir.list()) {
        if (entity is File && entity.path.endsWith(backupExtension)) {
          backups.add(entity);
        }
      }
      
      // Sort by modification time (newest first)
      backups.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return backups;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }
}

