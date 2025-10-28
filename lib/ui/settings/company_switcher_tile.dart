// lib/ui/settings/company_switcher_tile.dart
import 'package:flutter/material.dart';
import '../../services/org_service.dart';

class CompanySwitcherTile extends StatefulWidget {
  const CompanySwitcherTile({super.key});
  @override
  State<CompanySwitcherTile> createState() => _CompanySwitcherTileState();
}

class _CompanySwitcherTileState extends State<CompanySwitcherTile> {
  final svc = OrgService();
  String? _active;
  List<Map<String,Object?>> _companies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await svc.activeCompanyId();
    final list = await svc.listCompanies();
    setState(() { _active = a; _companies = list; });
  }

  @override
  Widget build(BuildContext context) {
    final activeName = _companies.firstWhere(
          (c) => c['id'] == _active,
      orElse: () => const {'name':'None'},
    )['name'] as String;
    return ListTile(
      leading: const Icon(Icons.business),
      title: Text('Active company: $activeName'),
      subtitle: const Text('Tap to switch'),
      onTap: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => ListView(
            children: _companies.map((c) => ListTile(
              title: Text(c['name'] as String),
              subtitle: Text('Code: ${c['company_code']}'),
              trailing: (c['id'] == _active) ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, c['id'] as String),
            )).toList(),
          ),
        );
        if (choice != null && choice != _active) {
          await svc.switchCompany(choice);
          await _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Company switched')),
            );
          }
        }
      },
    );
  }
}
