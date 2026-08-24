import '../../../../models/chat/message_model.dart';
import '../../../../models/student/course_module.dart';
import '../entities/module_tutor_chunk.dart';

/// Frontière du domaine vers l'assistant IA dédié à un module : un chat
/// restreint au contexte du cours.
abstract class ModuleTutorRepository {
  Stream<ModuleTutorChunk> sendMessage({
    required CourseModule module,
    required List<ChatMessage> messages,
  });

  void dispose();
}
