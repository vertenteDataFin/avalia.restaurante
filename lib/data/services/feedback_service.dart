import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/feedback_item.dart';
import '../models/admin_user.dart';

class FeedbackService extends ChangeNotifier {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal() {
    _initFirestoreListener();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  List<FeedbackItem> _feedbacks = [];
  List<AdminUser> _pendingAdmins = [];
  List<AdminUser> _activeUsers = [];
  AdminUser? _currentAdmin;

  List<FeedbackItem> get feedbacks => _feedbacks;
  List<AdminUser> get pendingAdmins => _pendingAdmins;
  List<AdminUser> get activeUsers => _activeUsers;
  AdminUser? get currentAdmin => _currentAdmin;

  void _initFirestoreListener() {
    // 1. Escuta em tempo real a coleção 'feedbacks' do Cloud Firestore
    _firestore
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _feedbacks = snapshot.docs.map((doc) {
          final data = doc.data();
          DateTime date;
          if (data['createdAt'] is Timestamp) {
            date = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is String) {
            date = DateTime.parse(data['createdAt']);
          } else {
            date = DateTime.now();
          }

          return FeedbackItem(
            id: doc.id,
            unit: data['unit'] ?? 'Pedra',
            foodRating: data['foodRating'] ?? 'Boa',
            type: data['type'] ?? 'Elogio',
            message: data['message'] ?? '',
            imageUrl: data['imageUrl'],
            createdAt: date,
          );
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erro ao ouvir Firestore feedbacks: $error');
      },
    );

    // 2. Escuta em tempo real os administradores pendentes de aprovação (isApproved == false)
    _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        _pendingAdmins = snapshot.docs.map((doc) {
          final data = doc.data();
          return AdminUser(
            uid: doc.id,
            email: data['email'] ?? '',
            name: data['name'] ?? 'Novo Usuário',
            isApproved: false,
            role: data['role'] ?? 'viewer',
          );
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erro ao ouvir administradores pendentes: $error');
      },
    );

    // 3. Escuta em tempo real os usuários ativos aprovados (isApproved == true)
    _firestore
        .collection('users')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        _activeUsers = snapshot.docs.map((doc) {
          final data = doc.data();
          return AdminUser(
            uid: doc.id,
            email: data['email'] ?? '',
            name: data['name'] ?? 'Usuário',
            isApproved: true,
            role: data['role'] ?? 'admin',
          );
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erro ao ouvir usuários ativos: $error');
      },
    );
  }

  Future<bool> addFeedback({
    required String foodRating,
    String unit = 'Pedra',
    String type = 'Geral',
    String message = '',
    String? imageUrl,
    Uint8List? imageBytes,
  }) async {
    String? finalImageUrl;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (imageBytes.length <= 1040000) {
        final base64Str = base64Encode(imageBytes);
        finalImageUrl = 'data:image/jpeg;base64,$base64Str';
      } else {
        debugPrint('Imagem descartada: ${imageBytes.length} bytes excede limite de 1MB');
      }
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image') || imageUrl.startsWith('http')) {
        finalImageUrl = imageUrl;
      }
    }

    try {
      await _firestore.collection('feedbacks').add({
        'unit': unit,
        'foodRating': foodRating,
        'type': type,
        'message': message,
        'imageUrl': finalImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar no Firestore: $e');
      return false;
    }
  }

  Future<void> deleteFeedback(String id) async {
    try {
      await _firestore.collection('feedbacks').doc(id).delete();
    } catch (e) {
      debugPrint('Erro ao excluir no Firestore: $e');
      _feedbacks.removeWhere((f) => f.id == id);
      notifyListeners();
    }
  }

  // Aprovação e Gestão de Usuários e Papéis pelo Administrador
  Future<void> approveAdmin(String uid, {String role = 'viewer'}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isApproved': true,
        'role': role,
      });
    } catch (e) {
      debugPrint('Erro ao aprovar usuário no Firestore: $e');
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar papel do usuário no Firestore: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('Erro ao excluir usuário no Firestore: $e');
    }
  }

  Future<void> rejectAdmin(String uid) async {
    return deleteUser(uid);
  }

  // Admin Auth & Approval Logic via Firestore & Firebase Auth
  Future<String?> loginAdmin(String email, String password) async {
    // 0. Acesso mestre Super-Admin para testes
    if (email.trim().toLowerCase() == 'admin@restaurante.com' && password == '123456') {
      _currentAdmin = AdminUser(
        uid: 'admin-demo',
        email: 'admin@restaurante.com',
        name: 'Gerente Principal',
        isApproved: true,
        role: 'admin',
      );
      notifyListeners();
      return null;
    }

    try {
      // 1. Tenta autenticar no Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) return 'Erro na autenticação.';

      // 2. Consulta documento do admin no Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return 'Perfil de usuário não encontrado no banco de dados.';
      }

      final userData = userDoc.data()!;
      final bool isApproved = userData['isApproved'] ?? false;

      if (!isApproved) {
        await _firebaseAuth.signOut();
        return 'Seu cadastro ainda está pendente de aprovação por um administrador.';
      }

      _currentAdmin = AdminUser(
        uid: uid,
        email: userData['email'] ?? email,
        name: userData['name'] ?? 'Usuário',
        isApproved: true,
        role: userData['role'] ?? 'admin',
      );
      notifyListeners();
      return null; // Sucesso
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'E-mail ou senha incorretos (${e.code}). Verifique se o e-mail e senha estão cadastrados na aba Authentication > Users no Firebase.';
      }
      return '[${e.code}] ${e.message ?? 'Erro ao realizar login.'}';
    } catch (e) {
      return 'Erro na conexão: $e';
    }
  }

  Future<String?> registerAdmin(String name, String email, String password) async {
    try {
      // 1. Cria usuário no Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) return 'Erro ao criar conta de usuário.';

      // 2. Cria documento de usuário no Firestore com isApproved: false e role: viewer por padrão
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'isApproved': false, // Inicia como FALSO para aprovação manual no Firestore
        'role': 'viewer',    // Papel padrão ao se cadastrar
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firebaseAuth.signOut();
      return null; // Sucesso no registro
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found') {
        return 'O método de E-mail/Senha precisa ser ativado no Firebase Console (Authentication > Sign-in method).';
      }
      return e.message ?? 'Erro ao registrar conta de usuário.';
    } catch (e) {
      return 'Erro ao salvar perfil: $e';
    }
  }

  Future<void> logoutAdmin() async {
    await _firebaseAuth.signOut();
    _currentAdmin = null;
    notifyListeners();
  }
}
