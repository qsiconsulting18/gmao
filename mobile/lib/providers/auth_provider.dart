import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/push/push_service.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class AuthState {
  final AppUser? user;
  final Tenant? tenant;
  final bool checking;

  AuthState({this.user, this.tenant, this.checking = true});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, Tenant? tenant, bool? checking}) {
    return AuthState(
      user: user ?? this.user,
      tenant: tenant ?? this.tenant,
      checking: checking ?? this.checking,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return AuthState();
  }

  Future<void> _restoreSession() async {
    final token = await SecureStorage.readToken();
    if (token == null) {
      state = state.copyWith(checking: false);
      return;
    }
    try {
      final res = await DioClient.instance.get('/auth/me');
      state = AuthState(
        user: AppUser.fromJson(res.data),
        tenant: Tenant.fromJson(res.data['tenant']),
        checking: false,
      );
    } catch (_) {
      await SecureStorage.clearToken();
      state = state.copyWith(checking: false);
    }
  }

  Future<void> login(String email, String password) async {
    final res = await DioClient.instance.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await SecureStorage.saveToken(res.data['token']);
    state = AuthState(
      user: AppUser.fromJson(res.data['user']),
      tenant: Tenant.fromJson(res.data['tenant']),
      checking: false,
    );
    PushService.registerCurrentToken();
  }

  Future<void> logout() async {
    await PushService.clearToken();
    try {
      await DioClient.instance.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout — clear the local session regardless.
    }
    await SecureStorage.clearToken();
    state = AuthState(checking: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
