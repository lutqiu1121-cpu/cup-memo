import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../models/entry.dart';
import '../../providers/app_providers.dart';
import '../../services/entry_service.dart';

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});
  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
  List<Entry> _archives = const <Entry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_reload);
  }

  Future<void> _reload() async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final List<Entry> entries = await service.list(category: '归档');
    if (mounted) setState(() { _archives = entries; _loading = false; });
  }

  Future<void> _open(Entry entry) async {
    final EntryService? service = ref.read(entryServiceProvider);
    if (service == null) return;
    final String body = await service.readBody(entry);
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(entry.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
        MarkdownBody(data: body, selectable: true),
      ]),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('归档')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _archives.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: '还没有归档内容',
                    description: '完成会话归档后，Markdown 会同步写入 entries 并在这里展示。',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _archives.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int index) {
                      final Entry entry = _archives[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(entry.title),
                          subtitle: Text(entry.updatedAt.toLocal().toString()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(entry),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
