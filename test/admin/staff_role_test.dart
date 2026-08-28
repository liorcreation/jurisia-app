import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/admin/auth/staff_role.dart';

void main() {
  group('StaffRole', () {
    test('roundtrip nom en base pour tous les rôles', () {
      for (final role in StaffRole.values) {
        expect(StaffRole.fromWireName(role.wireName), role);
      }
    });

    test('un nom inconnu ou nul donne null', () {
      expect(StaffRole.fromWireName('root'), isNull);
      expect(StaffRole.fromWireName(null), isNull);
    });
  });

  group('StaffIdentity', () {
    test('sans rôle : pas membre du personnel', () {
      const identity = StaffIdentity.none();
      expect(identity.isStaff, isFalse);
      expect(identity.canOperate, isFalse);
      expect(identity.canSeeBilling, isFalse);
      expect(identity.primary, isNull);
    });

    test('agent support : opère mais ne voit pas la facturation', () {
      const identity = StaffIdentity({StaffRole.supportAgent});
      expect(identity.isStaff, isTrue);
      expect(identity.canOperate, isTrue);
      expect(identity.canSeeBilling, isFalse);
    });

    test('analyste : voit la facturation mais n\'opère pas', () {
      const identity = StaffIdentity({StaffRole.analyst});
      expect(identity.canOperate, isFalse);
      expect(identity.canSeeBilling, isTrue);
    });

    test('super admin : tout', () {
      const identity = StaffIdentity({StaffRole.superAdmin});
      expect(identity.canOperate, isTrue);
      expect(identity.canSeeBilling, isTrue);
      expect(identity.primary, StaffRole.superAdmin);
    });

    test('primary renvoie le rôle le plus élevé', () {
      const identity = StaffIdentity({StaffRole.analyst, StaffRole.admin});
      expect(identity.primary, StaffRole.admin);
    });
  });
}
