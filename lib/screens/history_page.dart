import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AuthService.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _problems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserHistory();
  }

  Future<void> _fetchUserHistory() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null || user['id'] == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('https://dramane10.pythonanywhere.com/api/math-problems/?user_id=${user['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _problems = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement de l\'historique');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Problèmes'),
        backgroundColor: AuthService.primaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchUserHistory,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_problems.isEmpty) {
      return const Center(child: Text('Aucun problème résolu pour le moment'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _problems.length,
      itemBuilder: (context, index) {
        final problem = _problems[index];
        return _buildProblemCard(problem);
      },
    );
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Type: ${problem['input_type']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDate(problem['created_at']),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (problem['extracted_problem'] != null)
              Text(
                'Problème: ${problem['extracted_problem']}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 8),
            Text(
              'Solution: ${problem['solution']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (problem['processing_time'] != null)
              Text(
                'Temps de traitement: ${problem['processing_time']}s',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}