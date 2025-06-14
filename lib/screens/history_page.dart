import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LoginPage.dart'; // Import the LoginPage

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String _apiEndpoint = 'https://4335-102-180-159-126.ngrok-free.app/api/user/problems/';
  List<dynamic> _historyItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _historyItems = data;
          _isLoading = false;
          _isAuthenticated = true;
        });
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Veuillez vous connecter pour voir votre historique';
          _isLoading = false;
          _isAuthenticated = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showLoginDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onLoginSuccess: () {
            Navigator.of(context).pop(true); // Close the login page
            _fetchHistory(); // Refresh history after successful login
          },
        ),
      ),
    );

    if (result == true) {
      await _fetchHistory();
    }
  }

  // ... keep all the existing methods (_formatDate, build, _showSolutionDetails) the same ...

 @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (!_isAuthenticated || _errorMessage.isNotEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showLoginDialog,
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  if (_historyItems.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun historique disponible'),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _fetchHistory,
    child: ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        return Card(
          // ... (le reste de votre Card widget)
        );
      },
    ),
  );
}
}