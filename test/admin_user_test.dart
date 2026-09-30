import 'package:flutter_test/flutter_test.dart';
import 'package:app_mob_alimento/data/models/admin_user.dart';

void main() {
  group('AdminUser Roles and Permissions Tests', () {
    test('Admin role has all permissions (delete and manage users)', () {
      final admin = AdminUser(
        uid: 'user-admin-1',
        email: 'gerente@empresa.com',
        name: 'Gerente Geral',
        isApproved: true,
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isViewer, isFalse);
      expect(admin.canDelete, isTrue);
      expect(admin.canManageUsers, isTrue);
      expect(admin.roleLabel, 'Administrador');
    });

    test('Viewer role can only view (cannot delete or manage users)', () {
      final viewer = AdminUser(
        uid: 'user-viewer-1',
        email: 'auditor@empresa.com',
        name: 'Auditor de Qualidade',
        isApproved: true,
        role: 'viewer',
      );

      expect(viewer.isAdmin, isFalse);
      expect(viewer.isViewer, isTrue);
      expect(viewer.canDelete, isFalse);
      expect(viewer.canManageUsers, isFalse);
      expect(viewer.roleLabel, 'Visualizador');
    });

    test('AdminUser JSON serialization and deserialization works correctly', () {
      final user = AdminUser(
        uid: 'user-123',
        email: 'teste@empresa.com',
        name: 'Carlos Teste',
        isApproved: true,
        role: 'viewer',
      );

      final json = user.toJson();
      expect(json['uid'], 'user-123');
      expect(json['role'], 'viewer');
      expect(json['isApproved'], isTrue);

      final fromJson = AdminUser.fromJson(json);
      expect(fromJson.uid, user.uid);
      expect(fromJson.role, 'viewer');
      expect(fromJson.isViewer, isTrue);
    });
  });
}
