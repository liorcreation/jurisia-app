import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jurisia_app/core/entitlements/entitlements_controller.dart';
import 'package:jurisia_app/core/entitlements/entitlements_repository.dart';
import 'package:jurisia_app/core/entitlements/plan.dart';
import 'package:jurisia_app/core/shell/profile_sheet.dart';
import 'package:jurisia_app/features/auth/domain/entities/auth_user.dart';
import 'package:jurisia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:jurisia_app/features/profile/domain/entities/user_profile.dart';
import 'package:jurisia_app/features/profile/domain/entities/user_profession.dart';
import 'package:jurisia_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:jurisia_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:jurisia_app/theme/app_theme.dart';

class _EntitlementsRepository implements EntitlementsRepository {
  @override
  Future<EntitlementsSnapshot?> load() async =>
      const EntitlementsSnapshot(plan: PlanCode.decouverte);

  @override
  Future<void> recordUsage(String feature) async {}
}

class _ProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> load() async => const UserProfile(
    id: 'test-user',
    email: 'awa@example.com',
    fullName: 'Awa Traoré',
  );

  @override
  Future<void> save({String? fullName, UserProfession? profession}) async {}
}

class _AuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> recordTermsAcceptance() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? profession,
  }) async {}
}

void main() {
  testWidgets('le profil mène aux offres et à ses documents juridiques', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entitlements = EntitlementsController(
      repository: _EntitlementsRepository(),
      usageScope: null,
    );
    final profile = ProfileController(
      profileRepository: _ProfileRepository(),
      authRepository: _AuthRepository(),
    );
    addTearDown(entitlements.dispose);
    addTearDown(profile.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EntitlementsController>.value(
            value: entitlements,
          ),
          ChangeNotifierProvider<ProfileController>.value(value: profile),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showProfileSheet(context),
                  child: const Text('Ouvrir mon compte'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir mon compte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester.takeException(),
      isNull,
      reason: 'ouverture de la feuille profil',
    );
    expect(find.text('FORMULE ACTUELLE'), findsOneWidget);
    expect(find.text('DOCUMENTS ET INFORMATIONS'), findsOneWidget);

    await tester.tap(find.text('FORMULE ACTUELLE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final subscriptionLayoutError = tester.takeException();
    if (subscriptionLayoutError != null) {
      fail(subscriptionLayoutError.toStringDeep());
    }
    expect(find.text('Passez à la vitesse supérieure'), findsOneWidget);
    expect(find.text('Conditions générales d\'utilisation'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsAtLeastNWidgets(1));

    await tester.ensureVisible(
      find.text('Conditions générales d\'utilisation'),
    );
    await tester.tap(find.text('Conditions générales d\'utilisation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: 'ouverture des CGU');
    expect(find.text('Conditions Générales d\'Utilisation'), findsOneWidget);
  });
}
