import 'dart:io';

import 'package:flutter/material.dart';

import '../services/device_bridge.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    DownloadManager.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    DownloadManager.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _statusText(DownloadTask t) {
    switch (t.status) {
      case DownloadStatus.queued:
        return '排队中';
      case DownloadStatus.resolving:
        return '解析链接中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return t.error ?? '下载失败';
      case DownloadStatus.canceled:
        return '已取消';
    }
  }

  Color _statusColor(DownloadTask t, NeuPalette p) {
    switch (t.status) {
      case DownloadStatus.queued:
      case DownloadStatus.resolving:
      case DownloadStatus.downloading:
        return p.accent;
      case DownloadStatus.completed:
        return p.success;
      case DownloadStatus.failed:
        return p.danger;
      case DownloadStatus.canceled:
        return p.subText;
    }
  }

  Future<void> _deleteRecord(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
    final records = Storage.instance.downloadRecords;
    records.removeWhere((r) => r['filePath'] == filePath);
    await Storage.instance.saveDownloadRecords(records);
    if (!mounted) return;
    setState(() {});
    showToast(context, '已删除');
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final tasks = DownloadManager.instance.tasks;
    final records = Storage.instance.downloadRecords;
    return Scaffold(
      appBar: NeuAppBar(
        title: '下载管理',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: (tasks.isEmpty && records.isEmpty)
          ? const EmptyView(message: '还没有下载任务\n去应用详情页试试下载吧', icon: Icons.download_outlined)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                if (tasks.isNotEmpty) ...<Widget>[
                  SectionHeader(title: '进行中（${tasks.length}）'),
                  ...tasks.map((DownloadTask t) => _taskCard(t, p)),
                ],
                if (records.isNotEmpty) ...<Widget>[
                  SectionHeader(title: '下载记录（${records.length}）'),
                  ...records.map((Map<String, dynamic> r) => _recordCard(r, p)),
                ],
              ],
            ),
    );
  }

  Widget _taskCard(DownloadTask t, NeuPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuBox(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t.appTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText(t),
                  style: TextStyle(color: _statusColor(t, p), fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (t.isActive)
              NeuProgress(
                value: t.total > 0 ? t.progress : 0.0,
                height: 10,
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t.total > 0
                        ? '${(t.received / 1024 / 1024).toStringAsFixed(1)} MB / ${(t.total / 1024 / 1024).toStringAsFixed(1)} MB'
                        : t.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.subText, fontSize: 11.5),
                  ),
                ),
                if (t.isActive)
                  NeuIconButton(
                    icon: Icons.close,
                    size: 32,
                    onPressed: () => DownloadManager.instance.cancel(t.appId),
                  ),
                if (t.status == DownloadStatus.completed) ...<Widget>[
                  NeuButton(
                    text: '安装',
                    compact: true,
                    onPressed: () => DownloadManager.instance.open(t),
                  ),
                  const SizedBox(width: 8),
                  NeuIconButton(
                    icon: Icons.delete_outline,
                    size: 32,
                    onPressed: () => DownloadManager.instance.remove(t.appId),
                  ),
                ],
                if (t.status == DownloadStatus.failed) ...<Widget>[
                  NeuButton(
                    text: '重试',
                    compact: true,
                    onPressed: () => DownloadManager.instance.start(
                      appId: t.appId,
                      appTitle: t.appTitle,
                      url: t.url,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeuIconButton(
                    icon: Icons.delete_outline,
                    size: 32,
                    onPressed: () => DownloadManager.instance.remove(t.appId),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> r, NeuPalette p) {
    final filePath = (r['filePath'] ?? '').toString();
    final exists = filePath.isNotEmpty && File(filePath).existsSync();
    final total = r['total'];
    final totalText = total is int && total > 0 ? '${(total / 1024 / 1024).toStringAsFixed(1)} MB' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuBox(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (r['appTitle'] ?? '应用').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      (r['fileName'] ?? '').toString(),
                      if (totalText.isNotEmpty) totalText,
                      if (!exists) '文件已不存在',
                    ].where((String s) => s.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.subText, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (exists) ...<Widget>[
              NeuIconButton(
                icon: Icons.install_mobile_outlined,
                size: 36,
                onPressed: () => DeviceBridge.instance.openApk(filePath),
              ),
              const SizedBox(width: 8),
            ],
            NeuIconButton(
              icon: Icons.delete_outline,
              size: 36,
              onPressed: () => _deleteRecord(filePath),
            ),
          ],
        ),
      ),
    );
  }
}
