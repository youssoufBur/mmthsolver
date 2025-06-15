import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Configuration
  static const String _baseUrl = 'https://dramane10.pythonanywhere.com';
  static const String _loginEndpoint = '/api/login/';       // Corrigé
  static const String _registerEndpoint = '/api/register/'; // Corrigé
  static const String _profileEndpoint = '/api/profile/';   // Corrigé

  // Couleurs de l'application
  static const Color primaryColor = Color(0xFFF57C00); // Orange
  static const Color secondaryColor = Color(0xFF26A69A); // Teal

  // Méthode de connexion améliorée
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      debugPrint('Tentative de connexion pour $username');
      final url = Uri.parse('$_baseUrl$_loginEndpoint');
      debugPrint('URL de la requête: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Statut de la réponse: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      final responseData = _handleResponse(response);

      // Sauvegarde des données utilisateur
      await _saveUserData(responseData['user']);

      debugPrint('Connexion réussie pour ${responseData['user']['username']}');
      return responseData;
    } catch (e) {
      debugPrint('Erreur de connexion détaillée: ${e.toString()}');
      throw _handleError(e);
    }
  }

  // Méthode d'inscription améliorée
  static Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String password, {
    String firstName = '',
    String lastName = '',
  }) async {
    try {
      debugPrint('Tentative d\'inscription pour $username');
      final url = Uri.parse('$_baseUrl$_registerEndpoint');
      debugPrint('URL de la requête: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Statut de la réponse: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      final responseData = _handleResponse(response);
      await _saveUserData(responseData['user']);
      
      debugPrint('Inscription réussie pour ${responseData['user']['username']}');
      return responseData;
    } catch (e) {
      debugPrint('Erreur d\'inscription détaillée: ${e.toString()}');
      throw _handleError(e);
    }
  }

  // Gestion améliorée des réponses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final contentType = response.headers['content-type'];
      
      // Vérification du type de contenu
      if (contentType == null || !contentType.toLowerCase().contains('application/json')) {
        debugPrint('Réponse inattendue (type: $contentType): ${response.body}');
        throw Exception('Le serveur a retourné une réponse non-JSON');
      }

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      switch (response.statusCode) {
        case 200:
          return responseData;
        case 400:
          throw Exception(responseData['error'] ?? 'Requête incorrecte');
        case 401:
          throw Exception(responseData['error'] ?? 'Authentification requise');
        case 403:
          throw Exception(responseData['error'] ?? 'Permission refusée');
        case 404:
          throw Exception('Endpoint non trouvé');
        case 500:
          throw Exception('Erreur interne du serveur');
        default:
          throw Exception('Erreur inattendue (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement de la réponse: $e');
      rethrow;
    }
  }

  // Sauvegarde des données utilisateur
  static Future<void> _saveUserData(Map<String, dynamic> user) async {
    try {
      if (user['id'] == null || user['username'] == null) {
        throw Exception('Données utilisateur incomplètes');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user));

      debugPrint('Utilisateur sauvegardé avec succès: ${user['username']}');
    } catch (e) {
      debugPrint('Erreur de sauvegarde: $e');
      throw Exception('Échec de la sauvegarde des données utilisateur');
    }
  }

  // Gestion améliorée des erreurs
  static String _handleError(dynamic e) {
    debugPrint('Type d\'erreur: ${e.runtimeType}');

    if (e is http.ClientException) {
      return 'Erreur de connexion au serveur';
    } else if (e is TimeoutException) {
      return 'Le serveur ne répond pas - temps d\'attente dépassé';
    } else if (e is FormatException) {
      return 'Format de réponse serveur invalide';
    } else if (e is String) {
      return e;
    } else if (e is Exception) {
      final message = e.toString();
      return message.replaceAll('Exception: ', '');
    }
    return 'Une erreur inattendue est survenue';
  }

  // Récupération de l'utilisateur courant
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString == null) {
        debugPrint('Aucun utilisateur trouvé en cache');
        return null;
      }

      final userData = json.decode(userString) as Map<String, dynamic>;
      if (userData['id'] == null) {
        debugPrint('Données utilisateur invalides en cache');
        return null;
      }

      return userData;
    } catch (e) {
      debugPrint('Erreur de récupération utilisateur: $e');
      return null;
    }
  }

  // Vérification de l'état de connexion
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null && user['id'] != null;
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      debugPrint('Utilisateur déconnecté avec succès');
    } catch (e) {
      debugPrint('Erreur de déconnexion: $e');
      throw Exception('Échec de la déconnexion');
    }
  }
}