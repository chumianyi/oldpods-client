import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'device_bridge.dart';
import 'lanzou.dart';
import 'storage.dart';

enum DownloadStatus { queued, resolving, downloading, completed, failed, canceled }

class DownloadTask {
  final int appId;
  final String appTitle;
  final String url;
  final String fileName;
  DownloadStatus status;
  int received;
  int total;
  String? filePath;
  String? error;

  DownloadTask({
    required this.appId,
    required this.appTitle,
    required this.url,
    required this.fileName,
    this.status = DownloadStatus.queued,
    this.received = 0,
    this.total = 0,
    this.filePath,
    this.error,
  });

  double get progress => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);

  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.resolving || status == DownloadStatus.downloading;

  Map<String, dynamic> toRecord() => <String, dynamic>{
        'appId': appId,
        'appTitle': appTitle,
        'fileName': fileName,
        'url': url,
        'filePath': filePath,
        'total': total,
        'status': status == DownloadStatus.completed ? 'completed' : 'failed',
      };
}

class _Handles {
  StreamSubscription<List<int>>? subscription;
  http.Client? client;
  IOSink? sink;
}

/// 下载管理器：支持进度、取消、打开安装。
class DownloadManager extends ChangeNotifier {
  DownloadManager._();

  static final DownloadManager instance = DownloadManager._();

  final List<DownloadTask> _tasks = <DownloadTask>[];
  final Map<int, _Handles> _handles = <int, _Handles>{};

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadTask? taskOf(int appId) {
    for (final t in _tasks) {
      if (t.appId == appId) return t;
    }
    return null;
  }

  bool isActive(int appId) => taskOf(appId)?.isActive ?? false;

  void remove(int appId) {
    _tasks.removeWhere((t) => t.appId == appId);
    _handles.remove(appId);
    notifyListeners();
  }

  void cancel(int appId) {
    final t = taskOf(appId);
    if (t == null) return;
    t.status = DownloadStatus.canceled;
    final h = _handles.remove(appId);
    h?.subscription?.cancel();
    h?.client?.close();
    try {
      h?.sink?.close();
    } catch (_) {}
    _tasks.remove(t);
    notifyListeners();
  }

  /// 开始下载；lanzou 链接会先解析直链。
  Future<DownloadTask> start({
    required int appId,
    required String appTitle,
    required String url,
  }) async {
    final existing = taskOf(appId);
    if (existing != null && existing.isActive) {
      return existing;
    }
    final fileName = _safeName('${appTitle}_$appId.apk');
    final task = DownloadTask(appId: appId, appTitle: appTitle, url: url, fileName: fileName);
    _tasks.insert(0, task);
    notifyListeners();
    _run(task);
    return task;
  }

  Future<void> _run(DownloadTask task) async {
    final handles = _Handles();
    _handles[task.appId] = handles;
    try {
      var finalUrl = task.url;
      if (LanzouResolver.isLanzouUrl(finalUrl)) {
        task.status = DownloadStatus.resolving;
        notifyListeners();
        final direct = await LanzouResolver.instance.resolve(finalUrl);
        if (task.status == DownloadStatus.canceled) return;
        if (direct == null || direct.isEmpty) {
          task.status = DownloadStatus.failed;
          task.error = '蓝奏云链接解析失败，请复制链接到浏览器下载';
          notifyListeners();
          return;
        }
        finalUrl = direct;
      }

      final dirPath = await DeviceBridge.instance.downloadDir();
      final baseDir = Directory('${dirPath ?? '/storage/emulated/0/Download'}/oldpods');
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }
      final file = File('${baseDir.path}/${task.fileName}');
      final sink = file.openWrite();
      handles.sink = sink;

      final client = http.Client();
      handles.client = client;
      final request = http.Request('GET', Uri.parse(finalUrl));
      request.headers.addAll(ApiClient.instance.requestHeaders(referer: _refererFor(finalUrl)));
      final response = await client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('下载失败（HTTP ${response.statusCode}）');
      }
      task.total = response.contentLength ?? 0;
      task.status = DownloadStatus.downloading;
      notifyListeners();

      var lastNotify = DateTime.now().millisecondsSinceEpoch;
      final completer = Completer<void>();
      handles.subscription = response.stream.listen(
        (List<int> chunk) {
          if (task.status == DownloadStatus.canceled) return;
          sink.add(chunk);
          task.received += chunk.length;
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastNotify > 200) {
            lastNotify = now;
            notifyListeners();
          }
        },
        onDone: () async {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          if (task.status != DownloadStatus.canceled) {
            task.status = DownloadStatus.completed;
            task.filePath = file.path;
            _saveRecord(task);
            notifyListeners();
          }
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object error) async {
          try {
            await sink.close();
          } catch (_) {}
          if (task.status != DownloadStatus.canceled) {
            task.status = DownloadStatus.failed;
            task.error = '下载出错：$error';
            notifyListeners();
          }
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );
      await completer.future;
    } catch (e) {
      if (task.status != DownloadStatus.canceled) {
        task.status = DownloadStatus.failed;
        task.error = e.toString();
        notifyListeners();
      }
    } finally {
      handles.subscription?.cancel();
      handles.client?.close();
      _handles.remove(task.appId);
    }
  }

  String _refererFor(String url) {
    if (LanzouResolver.isLanzouUrl(url)) {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}/';
    }
    return '${ApiClient.baseUrl}/';
  }

  void _saveRecord(DownloadTask task) {
    final records = Storage.instance.downloadRecords;
    records.removeWhere((r) => r['appId'] == task.appId);
    records.insert(0, task.toRecord());
    Storage.instance.saveDownloadRecords(records);
  }

  static String _safeName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_');
  }

  Future<void> open(DownloadTask task) async {
    final path = task.filePath;
    if (path == null || !File(path).existsSync()) return;
    await DeviceBridge.instance.openApk(path);
  }
}
