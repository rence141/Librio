import 'package:flutter/foundation.dart';
import '../data/content_packs.dart';
import 'api_service.dart';

/// Content Service for managing educational content
class ContentService {
  static final ContentService _instance = ContentService._internal();
  
  factory ContentService() {
    return _instance;
  }
  
  ContentService._internal();
  
  late ApiService _apiService;
  final Map<String, ContentPack> _cachedPacks = {};
  
  /// Initialize content service
  Future<void> initialize(ApiService apiService) async {
    _apiService = apiService;
    
    // Load default content packs
    _loadDefaultPacks();
    
    if (kDebugMode) {
      print('✅ Content service initialized');
    }
  }
  
  /// Load default content packs
  void _loadDefaultPacks() {
    final packs = ContentPacks.getAllPacks();
    for (final pack in packs) {
      _cachedPacks[pack.subject] = pack;
    }
  }
  
  /// Get all content packs
  Future<List<ContentPack>> getAllPacks() async {
    try {
      // Try to fetch from backend
      final response = await _apiService.get<List<dynamic>>(
        endpoint: '/content/packs',
        fromJson: (data) => data as List<dynamic>,
      );
      
      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('📚 Fetched ${response.data!.length} packs from backend');
        }
        
        // Parse and cache packs
        // TODO: Implement proper parsing from backend response
        return _cachedPacks.values.toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch packs from backend: $e');
      }
    }
    
    // Return cached packs as fallback
    return _cachedPacks.values.toList();
  }
  
  /// Get pack by subject
  Future<ContentPack?> getPackBySubject(String subject) async {
    try {
      // Try to fetch from backend
      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint: '/content/packs/$subject',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('📚 Fetched pack for subject: $subject');
        }
        
        // TODO: Implement proper parsing from backend response
        return _cachedPacks[subject];
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch pack for subject: $e');
      }
    }
    
    // Return cached pack as fallback
    return _cachedPacks[subject];
  }
  
  /// Get topics for subject
  Future<List<ContentTopic>> getTopicsBySubject(String subject) async {
    try {
      final pack = await getPackBySubject(subject);
      if (pack != null) {
        return pack.topics;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get topics: $e');
      }
    }
    
    return [];
  }
  
  /// Get topic by ID
  Future<ContentTopic?> getTopicById(String topicId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint: '/content/topics/$topicId',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      
      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('📖 Fetched topic: $topicId');
        }
        
        // TODO: Implement proper parsing from backend response
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get topic: $e');
      }
    }
    
    return null;
  }
  
  /// Search content
  Future<List<PracticeProblem>> searchProblems(String query) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        endpoint: '/content/search?q=$query',
        fromJson: (data) => data as List<dynamic>,
      );
      
      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('🔍 Found ${response.data!.length} problems for: $query');
        }
        
        // TODO: Implement proper parsing from backend response
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Search failed: $e');
      }
    }
    
    return [];
  }
  
  /// Get featured content
  Future<List<ContentTopic>> getFeaturedContent() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        endpoint: '/content/featured',
        fromJson: (data) => data as List<dynamic>,
      );
      
      if (response.success && response.data != null) {
        if (kDebugMode) {
          print('⭐ Fetched featured content');
        }
        
        // TODO: Implement proper parsing from backend response
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get featured content: $e');
      }
    }
    
    return [];
  }
  
  /// Sync content with backend
  Future<bool> syncContent() async {
    try {
      if (kDebugMode) {
        print('🔄 Syncing content with backend');
      }
      
      final response = await _apiService.post(
        endpoint: '/content/sync',
        body: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response.success) {
        if (kDebugMode) {
          print('✅ Content synced');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Content sync failed: $e');
      }
    }
    
    return false;
  }
  
  /// Clear cache
  void clearCache() {
    _cachedPacks.clear();
    _loadDefaultPacks();
    
    if (kDebugMode) {
      print('🗑️ Content cache cleared');
    }
  }
}
