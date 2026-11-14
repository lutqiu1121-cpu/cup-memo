import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/github_service.dart';

class GitHubSettingsPage extends StatefulWidget {
  const GitHubSettingsPage({super.key});
  @override State<GitHubSettingsPage> createState() => _GitHubSettingsPageState();
}
class _GitHubSettingsPageState extends State<GitHubSettingsPage> {
  final TextEditingController _token = TextEditingController();
  final GitHubService _github = GitHubService();
  bool _hasToken = false;
  bool _saving = false;
  @override void initState() { super.initState(); Future<void>.microtask(_load); }
  Future<void> _load() async { _hasToken = (await _github.readToken())?.isNotEmpty == true; if (mounted) setState(() {}); }
  @override void dispose() { _token.dispose(); super.dispose(); }
  Future<void> _save() async {
    setState(() => _saving = true);
    if (_token.text.trim().isEmpty) { await _github.clearToken(); } else { await _github.saveToken(_token.text.trim()); }
    if (!mounted) return;
    setState(() { _saving = false; _hasToken = _token.text.trim().isNotEmpty; });
    _token.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GitHub Token 已安全保存')));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GitHub 集成')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: <Widget>[
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Personal Access Token', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_hasToken ? '已配置 Token（不会显示原文）' : '尚未配置 Token', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        TextField(controller: _token, obscureText: true, decoration: const InputDecoration(hintText: 'ghp_…', prefixIcon: Icon(Icons.key_outlined))),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中…' : '保存 / 清除')),
        const SizedBox(height: 8),
        const Text('Token 仅保存于系统安全沙盒。GitHub 文件工具会对读取内容做隐私脱敏。', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]))),
    ]),
  );
}
