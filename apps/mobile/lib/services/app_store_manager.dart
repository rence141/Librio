import 'package:flutter/foundation.dart';

/// App Store submission status
enum SubmissionStatus {
  draft,
  submitted,
  inReview,
  approved,
  rejected,
  released,
}

/// App Store metadata
class AppStoreMetadata {
  final String appName;
  final String appId;
  final String version;
  final String buildNumber;
  final String description;
  final String shortDescription;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String supportUrl;
  final List<String> keywords;
  final String category;
  final String rating; // 4+, 12+, 17+
  final List<String> screenshots;
  final String previewVideo;
  final DateTime releaseDate;

  AppStoreMetadata({
    required this.appName,
    required this.appId,
    required this.version,
    required this.buildNumber,
    required this.description,
    required this.shortDescription,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.supportUrl,
    required this.keywords,
    required this.category,
    required this.rating,
    required this.screenshots,
    required this.previewVideo,
    required this.releaseDate,
  });

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'appId': appId,
    'version': version,
    'buildNumber': buildNumber,
    'description': description,
    'shortDescription': shortDescription,
    'privacyPolicyUrl': privacyPolicyUrl,
    'termsOfServiceUrl': termsOfServiceUrl,
    'supportUrl': supportUrl,
    'keywords': keywords,
    'category': category,
    'rating': rating,
    'screenshots': screenshots,
    'previewVideo': previewVideo,
    'releaseDate': releaseDate.toIso8601String(),
  };
}

/// App Store submission
class AppStoreSubmission {
  final String id;
  final AppStoreMetadata metadata;
  final SubmissionStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? rejectionReason;
  final int versionCode;

  AppStoreSubmission({
    required this.id,
    required this.metadata,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.rejectionReason,
    required this.versionCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'metadata': metadata.toJson(),
    'status': status.toString(),
    'submittedAt': submittedAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewNotes': reviewNotes,
    'rejectionReason': rejectionReason,
    'versionCode': versionCode,
  };
}

/// App Store manager
class AppStoreManager {
  static final AppStoreManager _instance = AppStoreManager._internal();

  factory AppStoreManager() {
    return _instance;
  }

  AppStoreManager._internal();

  late AppStoreMetadata _metadata;
  late AppStoreSubmission _submission;
  final List<AppStoreSubmission> _submissionHistory = [];

  /// Initialize App Store manager
  void initialize(AppStoreMetadata metadata) {
    _metadata = metadata;

    if (kDebugMode) {
      print('🏪 App Store manager initialized');
    }
  }

  /// Create submission
  AppStoreSubmission createSubmission() {
    final submission = AppStoreSubmission(
      id: 'submission_${DateTime.now().millisecondsSinceEpoch}',
      metadata: _metadata,
      status: SubmissionStatus.draft,
      submittedAt: DateTime.now(),
      versionCode: int.parse(_metadata.buildNumber),
    );

    _submission = submission;

    if (kDebugMode) {
      print('📝 Submission created: ${submission.id}');
    }

    return submission;
  }

  /// Submit to App Store
  Future<bool> submitToAppStore() async {
    try {
      _submission = AppStoreSubmission(
        id: _submission.id,
        metadata: _submission.metadata,
        status: SubmissionStatus.submitted,
        submittedAt: _submission.submittedAt,
        versionCode: _submission.versionCode,
      );

      _submissionHistory.add(_submission);

      if (kDebugMode) {
        print('✅ Submitted to App Store: ${_submission.id}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Submission failed: $e');
      }

      return false;
    }
  }

  /// Update submission status
  void updateSubmissionStatus(SubmissionStatus status, {String? notes}) {
    _submission = AppStoreSubmission(
      id: _submission.id,
      metadata: _submission.metadata,
      status: status,
      submittedAt: _submission.submittedAt,
      reviewedAt: DateTime.now(),
      reviewNotes: notes,
      versionCode: _submission.versionCode,
    );

    if (kDebugMode) {
      print('📊 Status updated: ${status.toString()}');
    }
  }

  /// Get submission status
  SubmissionStatus getSubmissionStatus() {
    return _submission.status;
  }

  /// Get submission
  AppStoreSubmission? getSubmission() {
    return _submission;
  }

  /// Get submission history
  List<AppStoreSubmission> getSubmissionHistory() {
    return List.unmodifiable(_submissionHistory);
  }

  /// Validate metadata
  List<String> validateMetadata() {
    final errors = <String>[];

    if (_metadata.appName.isEmpty) errors.add('App name is required');
    if (_metadata.appId.isEmpty) errors.add('App ID is required');
    if (_metadata.version.isEmpty) errors.add('Version is required');
    if (_metadata.description.isEmpty) errors.add('Description is required');
    if (_metadata.shortDescription.isEmpty) errors.add('Short description is required');
    if (_metadata.privacyPolicyUrl.isEmpty) errors.add('Privacy policy URL is required');
    if (_metadata.keywords.isEmpty) errors.add('Keywords are required');
    if (_metadata.screenshots.isEmpty) errors.add('Screenshots are required');

    return errors;
  }

  /// Get compliance checklist
  Map<String, bool> getComplianceChecklist() {
    return {
      'appName': _metadata.appName.isNotEmpty,
      'appId': _metadata.appId.isNotEmpty,
      'version': _metadata.version.isNotEmpty,
      'description': _metadata.description.isNotEmpty,
      'shortDescription': _metadata.shortDescription.isNotEmpty,
      'privacyPolicy': _metadata.privacyPolicyUrl.isNotEmpty,
      'termsOfService': _metadata.termsOfServiceUrl.isNotEmpty,
      'supportUrl': _metadata.supportUrl.isNotEmpty,
      'keywords': _metadata.keywords.isNotEmpty,
      'category': _metadata.category.isNotEmpty,
      'rating': _metadata.rating.isNotEmpty,
      'screenshots': _metadata.screenshots.isNotEmpty,
      'previewVideo': _metadata.previewVideo.isNotEmpty,
    };
  }

  /// Get compliance percentage
  double getCompliancePercentage() {
    final checklist = getComplianceChecklist();
    final completed = checklist.values.where((v) => v).length;
    return (completed / checklist.length) * 100;
  }

  /// Generate submission report
  String generateSubmissionReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== App Store Submission Report ===\n');
    buffer.writeln('App Name: ${_metadata.appName}');
    buffer.writeln('Version: ${_metadata.version}');
    buffer.writeln('Build: ${_metadata.buildNumber}');
    buffer.writeln('Status: ${_submission.status.toString()}\n');

    buffer.writeln('Compliance Checklist:');
    final checklist = getComplianceChecklist();
    checklist.forEach((key, value) {
      buffer.writeln('  ${value ? "✅" : "❌"} $key');
    });

    buffer.writeln('\nCompliance: ${getCompliancePercentage().toStringAsFixed(1)}%');

    if (_submission.reviewNotes != null) {
      buffer.writeln('\nReview Notes:');
      buffer.writeln(_submission.reviewNotes);
    }

    if (_submission.rejectionReason != null) {
      buffer.writeln('\nRejection Reason:');
      buffer.writeln(_submission.rejectionReason);
    }

    buffer.writeln('\n=== End of Report ===');

    return buffer.toString();
  }
}
