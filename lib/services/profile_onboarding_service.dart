import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Standard role options presented to the user during profile onboarding.
enum UserRole {
  projectManager('Project Manager', 'PM, delivery lead, program owner'),
  engineer('Engineer', 'Software, civil, mechanical, electrical'),
  designer('Designer / UX', 'Product, UI/UX, service designer'),
  executive('Executive / Sponsor', 'Director, VP, C-level, sponsor'),
  consultant('Consultant / Advisor', 'External advisor, SME'),
  analyst('Analyst', 'Business, data, systems analyst'),
  other('Other', 'Anything else');

  const UserRole(this.label, this.description);
  final String label;
  final String description;

  String get firestoreValue => name;
}

/// Self-reported experience level.
enum ExperienceLevel {
  beginner('Beginner', 'New to project delivery or this kind of work'),
  intermediate('Intermediate', 'Some experience, comfortable with basics'),
  expert('Expert', 'Years of hands-on delivery experience'),
  executive('Executive overview', 'Need high-level dashboards, not detail');

  const ExperienceLevel(this.label, this.description);
  final String label;
  final String description;

  String get firestoreValue => name;
}

/// Project methodology the user prefers to start with.
enum PreferredMethodology {
  agile('Agile', 'Sprints, iterations, backlogs'),
  waterfall('Waterfall', 'Sequential phases, gated'),
  hybrid('Hybrid', 'Mix of both — phased with iterative delivery'),
  notSure('Not sure yet', 'Help me decide based on my project');

  const PreferredMethodology(this.label, this.description);
  final String label;
  final String description;

  String get firestoreValue => name;
}

/// Project type the user is most likely to deliver with NDU.
enum PrimaryProjectType {
  software('Software / IT', 'Apps, platforms, SaaS, integrations'),
  construction('Construction', 'Build, civil, infrastructure'),
  hardware('Hardware / Product', 'Devices, manufacturing, IoT'),
  services('Services / Ops', 'Service delivery, operations, rollout'),
  hybrid('Hybrid / Cross-domain', 'More than one of the above');

  const PrimaryProjectType(this.label, this.description);
  final String label;
  final String description;

  String get firestoreValue => name;
}

/// Captured answers from the profile-onboarding flow.
///
/// Persisted to Firestore at `users/{uid}/profile/onboarding`. Fields are
/// nullable because every step is skippable — only [completedAt] and
/// [skipped] are guaranteed once the flow finishes.
class ProfileOnboardingAnswers {
  final UserRole? role;
  final ExperienceLevel? experience;
  final String? industry;
  final int? teamSize;
  final String? primaryUseCase;
  final PrimaryProjectType? projectType;
  final PreferredMethodology? methodology;
  final DateTime? completedAt;
  final bool skipped;

  const ProfileOnboardingAnswers({
    this.role,
    this.experience,
    this.industry,
    this.teamSize,
    this.primaryUseCase,
    this.projectType,
    this.methodology,
    this.completedAt,
    this.skipped = false,
  });

  bool get isComplete =>
      !skipped &&
      role != null &&
      experience != null &&
      industry != null &&
      teamSize != null &&
      primaryUseCase != null &&
      projectType != null &&
      methodology != null;

  Map<String, dynamic> toFirestore() => {
        'role': role?.firestoreValue,
        'experience': experience?.firestoreValue,
        'industry': industry,
        'teamSize': teamSize,
        'primaryUseCase': primaryUseCase,
        'projectType': projectType?.firestoreValue,
        'methodology': methodology?.firestoreValue,
        'completedAt': completedAt != null
            ? Timestamp.fromDate(completedAt!)
            : null,
        'skipped': skipped,
        'updatedAt': Timestamp.now(),
      };

  factory ProfileOnboardingAnswers.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProfileOnboardingAnswers(
      role: _parseUserRole(data['role'] as String?),
      experience: _parseExperience(data['experience'] as String?),
      industry: data['industry'] as String?,
      teamSize: (data['teamSize'] as num?)?.toInt(),
      primaryUseCase: data['primaryUseCase'] as String?,
      projectType: _parseProjectType(data['projectType'] as String?),
      methodology: _parseMethodology(data['methodology'] as String?),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      skipped: (data['skipped'] as bool?) ?? false,
    );
  }

  static UserRole? _parseUserRole(String? v) {
    if (v == null) return null;
    try {
      return UserRole.values.byName(v);
    } catch (_) {
      return null;
    }
  }

  static ExperienceLevel? _parseExperience(String? v) {
    if (v == null) return null;
    try {
      return ExperienceLevel.values.byName(v);
    } catch (_) {
      return null;
    }
  }

  static PrimaryProjectType? _parseProjectType(String? v) {
    if (v == null) return null;
    try {
      return PrimaryProjectType.values.byName(v);
    } catch (_) {
      return null;
    }
  }

  static PreferredMethodology? _parseMethodology(String? v) {
    if (v == null) return null;
    try {
      return PreferredMethodology.values.byName(v);
    } catch (_) {
      return null;
    }
  }

  ProfileOnboardingAnswers copyWith({
    UserRole? role,
    ExperienceLevel? experience,
    String? industry,
    int? teamSize,
    String? primaryUseCase,
    PrimaryProjectType? projectType,
    PreferredMethodology? methodology,
    DateTime? completedAt,
    bool? skipped,
  }) {
    return ProfileOnboardingAnswers(
      role: role ?? this.role,
      experience: experience ?? this.experience,
      industry: industry ?? this.industry,
      teamSize: teamSize ?? this.teamSize,
      primaryUseCase: primaryUseCase ?? this.primaryUseCase,
      projectType: projectType ?? this.projectType,
      methodology: methodology ?? this.methodology,
      completedAt: completedAt ?? this.completedAt,
      skipped: skipped ?? this.skipped,
    );
  }
}

/// Service that persists profile-onboarding answers to Firestore and exposes
/// a stream of the current user's answers for redirect logic.
///
/// Document path: `users/{uid}/profile/onboarding`
class ProfileOnboardingService {
  ProfileOnboardingService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the current user's profile-onboarding document reference, or
  /// null if no user is signed in.
  static DocumentReference<Map<String, dynamic>>? _docRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('onboarding');
  }

  /// Saves the given answers to Firestore. Merges with existing data so
  /// partial saves (one step at a time) don't wipe previously-answered
  /// fields.
  static Future<void> save(ProfileOnboardingAnswers answers) async {
    final ref = _docRef();
    if (ref == null) {
      debugPrint(
          '[ProfileOnboardingService] Cannot save — no authenticated user.');
      return;
    }
    await ref.set(answers.toFirestore(), SetOptions(merge: true));
  }

  /// Marks the onboarding flow as completed (with whatever answers were
  /// collected). Called when the user finishes the last step or explicitly
  /// skips the entire flow.
  static Future<void> markComplete(ProfileOnboardingAnswers answers) async {
    final complete = answers.copyWith(
      completedAt: DateTime.now(),
      skipped: answers.skipped,
    );
    await save(complete);
  }

  /// Reads the current user's profile-onboarding answers, or null if there
  /// is no document yet (first-time user).
  static Future<ProfileOnboardingAnswers?> load() async {
    final ref = _docRef();
    if (ref == null) return null;
    try {
      final snap = await ref.get();
      if (!snap.exists) return null;
      return ProfileOnboardingAnswers.fromFirestore(
          snap as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      debugPrint('[ProfileOnboardingService] load error: $e');
      return null;
    }
  }

  /// Returns true if the user has completed profile onboarding (either by
  /// answering all questions or by explicitly skipping). Returns false for
  /// first-time users with no document.
  static Future<bool> hasCompleted() async {
    final answers = await load();
    if (answers == null) return false;
    return answers.completedAt != null;
  }
}
