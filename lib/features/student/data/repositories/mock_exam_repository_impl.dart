import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/student/course_module.dart';
import '../../../../models/student/mock_exam_model.dart';
import '../../domain/repositories/mock_exam_repository.dart';
import '../datasources/mock_exam_question_source.dart';

/// Implémentation du [MockExamRepository] : génération locale/IA des
/// questions ([MockExamQuestionSource]) et verrou/résultat portés
/// exclusivement par des RPC `security definer` côté serveur (voir
/// `server/supabase/migration_014_mock_exams.sql`) — jamais d'upsert client
/// direct sur l'état du verrou, pour qu'un client ne puisse pas se
/// déverrouiller lui-même.
class MockExamRepositoryImpl implements MockExamRepository {
  MockExamRepositoryImpl({
    required this.questionSource,
    this.supabaseClient,
    this.userId,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final MockExamQuestionSource questionSource;
  final SupabaseClient? supabaseClient;
  final String? userId;
  final Uuid _uuid;

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  Future<MockExamLockState> lockStateFor(String levelId) async {
    if (!_persistenceEnabled) return MockExamLockState(levelId: levelId);

    try {
      final rows = await supabaseClient!
          .from('student_mock_exam_state')
          .select('level_id, locked_until, requires_course_review')
          .eq('user_id', userId!)
          .eq('level_id', levelId)
          .limit(1);

      final row = rows.isEmpty ? null : rows.first;
      if (row == null) return MockExamLockState(levelId: levelId);
      return MockExamLockState.fromJson(row);
    } catch (error) {
      // ignore: avoid_print
      print("Échec du chargement du verrou d'examen blanc ($levelId) : $error");
      return MockExamLockState(levelId: levelId);
    }
  }

  @override
  Future<MockExam> generateExam({
    required String levelId,
    required List<CourseModule> levelModules,
    required MockExamMode mode,
  }) async {
    final set = await questionSource.generate(levelModules: levelModules, mode: mode);
    return MockExam(
      id: _uuid.v4(),
      levelId: levelId,
      mode: mode,
      questions: set.questions,
      generatedAt: DateTime.now(),
      isReducedFallback: set.isReducedFallback,
    );
  }

  @override
  Future<void> recordResult({required MockExam exam}) async {
    if (!_persistenceEnabled) return;
    try {
      await supabaseClient!.rpc('jurisia_record_mock_exam_result', params: {
        'p_level_id': exam.levelId,
        'p_mode': _modeParam(exam.mode),
        'p_score': exam.score ?? 0,
      });
    } catch (error) {
      // ignore: avoid_print
      print("Échec de l'enregistrement du résultat d'examen blanc (${exam.levelId}) : $error");
    }
  }

  @override
  Future<void> markCourseReviewed(String levelId) async {
    if (!_persistenceEnabled) return;
    try {
      await supabaseClient!.rpc('jurisia_mark_course_reviewed', params: {'p_level_id': levelId});
    } catch (error) {
      // ignore: avoid_print
      print('Échec de la levée de révision du cours ($levelId) : $error');
    }
  }

  String _modeParam(MockExamMode mode) {
    switch (mode) {
      case MockExamMode.qcmTimed:
        return 'qcm_timed';
      case MockExamMode.written:
        return 'written';
      case MockExamMode.oral:
        return 'oral';
    }
  }
}
