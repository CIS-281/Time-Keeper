import 'package:flutter/material.dart';
import 'package:time_keeper/services/org_service.dart';

class CompanySwitcherTile extends StatefulWidget {
  const CompanySwitcherTile({super.key});

  @override
  State<CompanySwitcherTile> createState() => _CompanySwitcherTileState();
}

class _CompanySwitcherTileState extends State<CompanySwitcherTile> {
  final _svc = OrgService();
  String? _activeId;
  List<Map<String, String>> _companies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await _svc.activeCompanyId();
    final list = await _svc.listCompanies(); // List<Map<String,String>>
    if (!mounted) return;
    setState(() {
      _activeId = id;
      _companies = list;
    });
  }

  Future<void> _pick() async {
    if (_companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No companies found on this device')),
      );
      return;
    }

    String? choice = _activeId;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Choose company', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final c in _companies)
              RadioListTile<String>(
                value: c['id']!,
                groupValue: choice,
                title: Text(c['name'] ?? ''),
                subtitle: Text('Code: ${c['code'] ?? ''}'),
                onChanged: (v) {
                  choice = v;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );

    if (choice != null && choice != _activeId) {
      await _svc.switchCompany(choice!);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company switched')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.swap_horiz),
      title: const Text('Switch Company'),
      subtitle: Text(
        _companies.isEmpty
            ? 'No companies on this device'
            : _companies.firstWhere(
              (e) => e['id'] == _activeId,
          orElse: () => <String, String>{
            'name': 'Unknown',
            'code': '',
            'id': _activeId ?? '',
          },
        )['name']!,
      ),
      onTap: _pick,
    );
  }
}
