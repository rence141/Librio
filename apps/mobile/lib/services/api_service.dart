import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  
  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
}

/// API Service for backend communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // TODO: Replace with actual backend URL
  static const String baseUrl = 'http://localhost:3000';
  static const Duration timeout = Duration(seconds: 30);
  
  late TokenManager _tokenManager;
  
  /// Initialize API service
  Future<void> initialize(TokenManager tokenManager) async {
    _tokenManager = tokenManager;
    
    if (kDebugMode) {
      print('✅ API service initialized');
    }
  }
  
  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenManager.getToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  /// POST request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) {
        print('📤 POST $endpoint');
      }
      
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          print('✅ POST $endpoint: ${response.statusCode}');
        }
        
        return ApiResponse(
          success: true,
          data: fromJson != null ? fromJson(data) : data as T,
          statusCode: response.statusCode,
        );
      } else {
        final error = _parseError(response);
        
        if (kDebugMode) {
          print('❌ POST $endpoint: ${response.statusCode} - $error');
        }
        
        return ApiResponse(
          success: false,
          error: error,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ POST $endpoint: $e');
      }
      
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
  
  /// GET request
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) {
        print('📥 GET $endpoint');
      }
      
      final response = await http
          .get(url, headers: headers)
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          print('✅ GET $endpoint: ${response.statusCode}');
        }
        
        return ApiResponse(
          success: true,
          data: fromJson != null ? fromJson(data) : data as T,
          statusCode: response.statusCode,
        );
      } else {
        final error = _parseError(response);
        
        if (kDebugMode) {
          print('❌ GET $endpoint: ${response.statusCode} - $error');
        }
        
        return ApiResponse(
          success: false,
          error: error,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GET $endpoint: $e');
      }
      
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
  
  /// PUT request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required Map<String, dynamic> body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) {
        print('📝 PUT $endpoint');
      }
      
      final response = await http
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          print('✅ PUT $endpoint: ${response.statusCode}');
        }
        
        return ApiResponse(
          success: true,
          data: fromJson != null ? fromJson(data) : data as T,
          statusCode: response.statusCode,
        );
      } else {
        final error = _parseError(response);
        
        if (kDebugMode) {
          print('❌ PUT $endpoint: ${response.statusCode} - $error');
        }
        
        return ApiResponse(
          success: false,
          error: error,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PUT $endpoint: $e');
      }
      
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
  
  /// DELETE request
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) {
        print('🗑️ DELETE $endpoint');
      }
      
      final response = await http
          .delete(url, headers: headers)
          .timeout(timeout);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          print('✅ DELETE $endpoint: ${response.statusCode}');
        }
        
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
        );
      } else {
        final error = _parseError(response);
        
        if (kDebugMode) {
          print('❌ DELETE $endpoint: ${response.statusCode} - $error');
        }
        
        return ApiResponse(
          success: false,
          error: error,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DELETE $endpoint: $e');
      }
      
      return ApiResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }
  
  /// Parse error from response
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['error'] ?? data['message'] ?? 'Unknown error';
    } catch (e) {
      return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
