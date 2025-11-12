import 'package:flutter/material.dart';
import '../../data/models/device_profile.dart';
import '../../data/repositories/device_profile_repository.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _repo = DeviceProfileRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController();
  final _device = TextEditingController();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _repo.get();
    _name.text = p?.fullName ?? '';
    _email.text = p?.email ?? '';
    _phone.text = p?.phone ?? '';
    _role.text = p?.role ?? '';
    _device.text = p?.deviceLabel ?? '';
    _avatarPath = p?.avatarPath;
    if (mounted) setState(() {});
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _avatarPath = x.path);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final p = DeviceProfile(
      fullName: _name.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      role: _role.text.trim().isEmpty ? null : _role.text.trim(),
      deviceLabel: _device.text.trim().isEmpty ? null : _device.text.trim(),
      avatarPath: _avatarPath,
    );
    await _repo.save(p);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: InkWell(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 44,
                backgroundImage: (_avatarPath != null) ? FileImage(File(_avatarPath!)) : null,
                child: (_avatarPath == null) ? const Icon(Icons.person, size: 44) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name *')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          TextField(controller: _role, decoration: const InputDecoration(labelText: 'Role')),
          TextField(controller: _device, decoration: const InputDecoration(labelText: 'Device label')),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
