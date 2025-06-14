import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './AuthService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'Français';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await AuthService.getUserData();
      if (data != null) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        final profile = await AuthService.getProfile();
        setState(() {
          _userData = profile['user'];
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userData?['first_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 48, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_userData?['first_name'] ?? ''} ${_userData?['last_name'] ?? ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _userData?['email'] ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _buildSettingsCard(context),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );

  }
    Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Mode sombre'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          ListTile(
            title: const Text('Langue'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Logique de sélection de langue à ajouter ici
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Se déconnecter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: _logout,
    );
  }


  // ... (rest of the ProfilePage code remains the same)
}