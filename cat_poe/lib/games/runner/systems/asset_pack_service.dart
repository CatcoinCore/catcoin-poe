import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../services/api_service.dart';

/// Service to handle on-demand downloading of game assets so the main app
/// stays lightweight. This downloads assets from the backend static folder.
class AssetPackService extends ChangeNotifier {
  final String packName;
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isReady = false;
  String _localPath = '';
  String _totalSizeDisplay = '0 MB';

  AssetPackService({required this.packName});

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  bool get isReady => _isReady;
  String get localPath => _localPath;
  String get totalSizeDisplay => _totalSizeDisplay;

  /// Check if the assets are already downloaded and complete
  Future<void> checkAssets() async {
    final directory = await getApplicationDocumentsDirectory();
    _localPath = p.join(directory.path, 'game_assets', packName);
    
    final manifestFile = File(p.join(_localPath, 'manifest.json'));
    String manifestContent;
    
    if (!await manifestFile.exists()) {
      try {
        final baseUrl = ApiService.baseUrl;
        final manifestUrl = '$baseUrl/static/game/$packName/manifest.json';
        final response = await http.get(Uri.parse(manifestUrl));
        if (response.statusCode == 200) {
          manifestContent = response.body;
          // We don't save it yet, only parse for size info
        } else {
          _isReady = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        _isReady = false;
        notifyListeners();
        return;
      }
    } else {
      manifestContent = await manifestFile.readAsString();
    }

    try {
      final manifest = jsonDecode(manifestContent);
      final List<dynamic> manifestAssets = manifest['assets'];
      
      bool allExist = true;
      int totalSizeBytes = 0;
      for (final asset in manifestAssets) {
        final String assetPath = asset is Map ? asset['path'] : asset.toString();
        if (asset is Map) {
          totalSizeBytes += (asset['size'] as int? ?? 0);
        }
        
        final localFilePath = p.join(_localPath, assetPath.replaceAll('/', Platform.pathSeparator));
        if (!await File(localFilePath).exists()) {
          allExist = false;
          // Keep calculating size even if not all exist
        }
      }
      
      _totalSizeDisplay = _formatSize(totalSizeBytes);
      _isReady = allExist;
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking assets: $e');
      _isReady = false;
    }
    notifyListeners();
  }

  /// Download the asset pack
  Future<void> downloadAssets() async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    _progress = 0.0;
    _isReady = false;
    notifyListeners();

    try {
      final baseUrl = ApiService.baseUrl;
      final manifestUrl = '$baseUrl/static/game/$packName/manifest.json';
      
      if (kDebugMode) debugPrint('Downloading manifest from: $manifestUrl');
      final response = await http.get(Uri.parse(manifestUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download manifest: ${response.statusCode}');
      }

      final manifest = jsonDecode(response.body);
      final List<dynamic> manifestAssets = manifest['assets'];
      
      // Calculate total size for reporting
      int totalSizeBytes = 0;
      for (final asset in manifestAssets) {
        if (asset is Map) {
          totalSizeBytes += (asset['size'] as int? ?? 0);
        }
      }
      _totalSizeDisplay = _formatSize(totalSizeBytes);
      
      // Ensure local directory exists
      final dir = Directory(_localPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      int downloadedCount = 0;
      for (final asset in manifestAssets) {
        final String assetPath = asset is Map ? asset['path'] : asset.toString();
        final fileUrl = '$baseUrl/static/game/$packName/$assetPath';
        final localFilePath = p.join(_localPath, assetPath.replaceAll('/', Platform.pathSeparator));
        
        // Ensure subdirectories exist
        final fileDir = Directory(p.dirname(localFilePath));
        if (!await fileDir.exists()) {
          await fileDir.create(recursive: true);
        }

        final file = File(localFilePath);
        // Always download if 0 bytes or missing to be safe during migration
        if (!await file.exists() || (await file.length()) == 0) {
          if (kDebugMode) debugPrint('Downloading: $fileUrl');
          final fileRes = await http.get(Uri.parse(fileUrl));
          if (fileRes.statusCode == 200) {
            await file.writeAsBytes(fileRes.bodyBytes);
          } else {
            throw Exception('Failed to download asset $assetPath: ${fileRes.statusCode}');
          }
        }

        downloadedCount++;
        _progress = downloadedCount / manifestAssets.length;
        notifyListeners();
      }
      
      // Save manifest ONLY after all assets are downloaded successfully
      final localManifest = File(p.join(_localPath, 'manifest.json'));
      await localManifest.writeAsBytes(response.bodyBytes);
      
      _isReady = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error downloading game assets: $e');
      _isReady = false;
      // Re-throw or handle error in UI
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Delete all local assets and manifest (for debugging/reset)
  Future<void> clearLocalAssets() async {
    final dir = Directory(_localPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _isReady = false;
    notifyListeners();
  }

  /// Get the full local path for a specific asset
  String getAssetPath(String assetRelativePath) {
    return p.join(_localPath, assetRelativePath.replaceAll('/', Platform.pathSeparator));
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 MB";
    double mb = bytes / (1024 * 1024);
    if (mb < 0.1) return "0.1 MB";
    return "${mb.toStringAsFixed(1)} MB";
  }
}

class RunnerAssetService extends AssetPackService {
  RunnerAssetService() : super(packName: 'runner');
}

class MiniGameAssetService extends AssetPackService {
  MiniGameAssetService() : super(packName: 'mini');
}

