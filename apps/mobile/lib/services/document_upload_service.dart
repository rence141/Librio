import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/document.dart';
import 'rag_service.dart';

/// Service for handling document uploads and text extraction
class DocumentUploadService {
  static final DocumentUploadService _instance = DocumentUploadService._internal();
  
  factory DocumentUploadService() {
    return _instance;
  }
  
  DocumentUploadService._internal();
  
  late RagService _ragService;
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize(RagService ragService) async {
    if (_isInitialized) return;
    
    _ragService = ragService;
    _isInitialized = true;
    
    if (kDebugMode) {
      print('✅ Document upload service initialized');
    }
  }
  
  /// Pick and upload a document
  Future<Document?> pickAndUploadDocument({
    required String category,
    required String source,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'docx'],
      );
      
      if (result == null || result.files.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No file selected');
        }
        return null;
      }
      
      final file = result.files.first;
      final filePath = file.path;
      
      if (filePath == null) {
        throw Exception('Invalid file path');
      }
      
      // Extract text based on file type
      String content = '';
      String title = file.name;
      
      if (file.extension == 'txt') {
        content = await _extractTextFromTxt(filePath);
      } else if (file.extension == 'pdf') {
        content = await _extractTextFromPdf(filePath);
      } else if (file.extension == 'docx') {
        content = await _extractTextFromDocx(filePath);
      } else {
        throw Exception('Unsupported file type: ${file.extension}');
      }
      
      if (content.isEmpty) {
        throw Exception('No text content found in file');
      }
      
      // Add document to RAG
      final document = await _ragService.addDocument(
        title: title,
        content: content,
        source: source,
        category: category,
      );
      
      if (kDebugMode) {
        print('✅ Document uploaded: ${document.id}');
      }
      
      return document;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upload document: $e');
      }
      rethrow;
    }
  }
  
  /// Extract text from TXT file
  Future<String> _extractTextFromTxt(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return content;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to extract text from TXT: $e');
      }
      rethrow;
    }
  }
  
  /// Extract text from PDF file (simplified - requires pdf package)
  Future<String> _extractTextFromPdf(String filePath) async {
    try {
      // For Phase 1D, we'll use a simple approach:
      // Read the file and extract basic text
      // In production, use a proper PDF library like 'pdf' or 'syncfusion_flutter_pdfviewer'
      
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Simple text extraction: look for text streams in PDF
      final content = _extractTextFromPdfBytes(bytes);
      
      if (content.isEmpty) {
        throw Exception('Could not extract text from PDF');
      }
      
      return content;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to extract text from PDF: $e');
      }
      rethrow;
    }
  }
  
  /// Extract text from DOCX file (simplified)
  Future<String> _extractTextFromDocx(String filePath) async {
    try {
      // DOCX is a ZIP file containing XML
      // For Phase 1D, we'll use a simple approach
      // In production, use a proper DOCX library like 'docx' or 'docx_to_text'
      
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Simple text extraction from DOCX
      final content = _extractTextFromDocxBytes(bytes);
      
      if (content.isEmpty) {
        throw Exception('Could not extract text from DOCX');
      }
      
      return content;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to extract text from DOCX: $e');
      }
      rethrow;
    }
  }
  
  /// Simple PDF text extraction (basic implementation)
  String _extractTextFromPdfBytes(List<int> bytes) {
    try {
      final content = String.fromCharCodes(bytes);
      
      // Simple regex to extract text between BT and ET markers
      final regex = RegExp(r'BT.*?ET', dotAll: true);
      final matches = regex.allMatches(content);
      
      final textParts = <String>[];
      for (final match in matches) {
        final text = match.group(0) ?? '';
        // Remove PDF operators and extract text
        final cleanText = text
            .replaceAll(RegExp(r'[/\(\)]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleanText.isNotEmpty) {
          textParts.add(cleanText);
        }
      }
      
      return textParts.join('\n');
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ PDF text extraction failed, returning empty: $e');
      }
      return '';
    }
  }
  
  /// Simple DOCX text extraction (basic implementation)
  String _extractTextFromDocxBytes(List<int> bytes) {
    try {
      final content = String.fromCharCodes(bytes);
      
      // DOCX XML contains text in <w:t> tags
      final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      final matches = regex.allMatches(content);
      
      final textParts = <String>[];
      for (final match in matches) {
        final text = match.group(1) ?? '';
        if (text.isNotEmpty) {
          textParts.add(text);
        }
      }
      
      return textParts.join(' ');
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DOCX text extraction failed, returning empty: $e');
      }
      return '';
    }
  }
  
  /// Get supported file types
  static List<String> get supportedFileTypes => ['txt', 'pdf', 'docx'];
  
  /// Check if file type is supported
  static bool isSupportedFileType(String extension) {
    return supportedFileTypes.contains(extension.toLowerCase());
  }
}
