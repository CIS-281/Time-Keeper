import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/models/device_profile.dart';
import '../../data/repositories/device_profile_repository.dart';

class ProfileOnboardingPage extends StatefulWidget {
  final VoidCallback onNext; // continue to your Create/Join Company screen
  const ProfileOnboardingPage({super.key, required this.onNext});

  @override
  State<ProfileOnboardingPage> createState() => _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
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
    _prefill();
  }

  Future<void> _prefill() async {
    final info = DeviceInfoPlugin();
    String label = 'This Device';
    try {
      final android = await info.androidInfo;
      label = android.model ?? 'Android';
    } catch (_) {
      try {
        final ios = await info.iosInfo;
        label = ios.utsname.machine ?? 'iPhone';
      } catch (_) {}
    }
    _device.text = label;

    final existing = await _repo.get();
    if (existing != null) {
      _name.text = existing.fullName ?? '';
      _email.text = existing.email ?? '';
      _phone.text = existing.phone ?? '';
      _role.text = existing.role ?? '';
      _device.text = existing.deviceLabel ?? label;
      _avatarPath = existing.avatarPath;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _avatarPath = x.path);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
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
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
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
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email (optional)')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
          TextField(controller: _role, decoration: const InputDecoration(labelText: 'Role (optional)')),
          TextField(controller: _device, decoration: const InputDecoration(labelText: 'Device label')),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Continue')),
        ],
      ),
    );
  }
}
