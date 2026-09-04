import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/staff_role.dart';
import 'admin_staff_member.dart';
import 'admin_staff_repository.dart';

/// État de l'écran « Personnel » : liste + actions d'octroi/retrait, chacune
/// tracée côté serveur. Les messages d'erreur du serveur (rôle invalide,
/// e-mail introuvable, dernier super_admin…) sont déjà en français et
/// actionnables — on les affiche tels quels plutôt que de les remplacer par
/// un message générique.
class AdminStaffController extends ChangeNotifier {
  AdminStaffController({required this.repository}) {
    // ignore: unawaited_futures
    load();
  }

  final AdminStaffRepository repository;

  List<AdminStaffMember> _members = const [];
  bool _loading = false;
  bool _mutating = false;
  String? _error;

  List<AdminStaffMember> get members => _members;
  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _members = await repository.list();
    } catch (error) {
      _error = 'Chargement du personnel impossible. Vérifiez vos droits.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// `true` en cas de succès (l'appelant peut alors vider son formulaire).
  Future<bool> grantRole({required String email, required StaffRole role}) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await repository.grantRole(email: email, role: role);
      await load();
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'L\'ajout n\'a pas pu être enregistré.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<void> revokeRole({required String userId, required StaffRole role}) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await repository.revokeRole(userId: userId, role: role);
      await load();
    } on PostgrestException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'Le retrait n\'a pas pu être enregistré.';
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }
}
