import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://4335-102-180-159-126.ngrok-free.app/api';
  static const String loginEndpoint = '$baseUrl/login/';
  static const String registerEndpoint = '$baseUrl/register/';
  static const String profileEndpoint = '$baseUrl/profile/';
  static const String logoutEndpoint = '$baseUrl/logout/';

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_data', json.encode(data['user']));
        return data;
      } else {
        throw Exception(data['message'] ?? 'Échec de la connexion');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(registerEndpoint),
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
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Échec de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Échec du chargement du profil');
      }
    } catch (e) {
      throw Exception('Erreur de profil: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse(logoutEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      // Clear local storage
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      if (response.statusCode != 200) {
        throw Exception('Échec de la déconnexion');
      }
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    return userData != null ? json.decode(userData) : null;
  }
}