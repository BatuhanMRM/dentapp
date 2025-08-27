import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as models;

class AuthService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı kayıt olma
  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
    models.UserType userType,
    String? specialty,
  ) async {
    try {
      // Basit validasyon
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        throw Exception('Tüm alanlar doldurulmalıdır');
      }

      if (!email.contains('@')) {
        throw Exception('Geçerli bir email adresi giriniz');
      }

      if (password.length < 6) {
        throw Exception('Şifre en az 6 karakter olmalıdır');
      }

      if (userType == models.UserType.doctor &&
          (specialty == null || specialty.isEmpty)) {
        throw Exception('Doktor için uzmanlık alanı gereklidir');
      }

      // Firebase'de kullanıcı oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Kullanıcı profilini güncelle
        await credential.user!.updateDisplayName(name);

        // Kullanıcı modelini oluştur
        final user = models.User(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          userType: userType,
          specialty: specialty,
          createdAt: DateTime.now(),
        );

        // SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();

        // Kullanıcıya özel key ile kaydet
        final userSpecificKey = 'user_${credential.user!.uid}';
        await prefs.setString(userSpecificKey, userToJson(user));

        // Aktif kullanıcı olarak da kaydet
        await prefs.setString(_userKey, userToJson(user));
        await prefs.setBool(_isLoggedInKey, true);

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Kayıt olma işlemi başarısız';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu email adresi zaten kullanımda';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/şifre ile kayıt olma devre dışı';
          break;
        default:
          errorMessage = 'Kayıt olma işlemi başarısız: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Kayıt olma işlemi başarısız: ${e.toString()}');
    }
  }

  // Kullanıcı giriş yapma
  Future<bool> login(String email, String password) async {
    try {
      // Basit validasyon
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email ve şifre gereklidir');
      }

      // Firebase ile giriş yap
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Kullanıcı bilgilerini al
        final prefs = await SharedPreferences.getInstance();

        // Kullanıcıya özel key oluştur
        final userSpecificKey = 'user_${credential.user!.uid}';
        String? userData = prefs.getString(userSpecificKey);

        if (userData == null) {
          // Kullanıcı bilgileri yoksa varsayılan hasta olarak oluştur
          final user = models.User(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? 'Kullanıcı',
            email: credential.user!.email ?? email,
            phone: '', // Firebase'de telefon numarası yoksa boş
            userType: models.UserType.patient, // Default hasta
            createdAt: DateTime.now(),
          );

          await prefs.setString(userSpecificKey, userToJson(user));
          userData = userToJson(user);
        }

        // Aktif kullanıcı bilgisini kaydet
        await prefs.setString(_userKey, userData);
        await prefs.setBool(_isLoggedInKey, true);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Giriş işlemi başarısız';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış';
          break;
        case 'too-many-requests':
          errorMessage =
              'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
          break;
        case 'invalid-credential':
          errorMessage = 'Email veya şifre hatalı';
          break;
        default:
          errorMessage = 'Giriş işlemi başarısız: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Giriş işlemi başarısız: ${e.toString()}');
    }
  }

  // Kullanıcı çıkış yapma
  Future<void> logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userKey);
    } catch (e) {
      throw Exception('Çıkış işlemi başarısız: ${e.toString()}');
    }
  }

  // Kullanıcının giriş yapıp yapmadığını kontrol et
  Future<bool> isLoggedIn() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_isLoggedInKey) ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Mevcut kullanıcıyı getir
  Future<models.User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        return userFromJson(userData);
      }

      // SharedPreferences'da yoksa Firebase'den al
      final user = models.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Kullanıcı',
        email: firebaseUser.email ?? '',
        phone: '',
        userType: models.UserType.patient, // Default hasta
        createdAt: DateTime.now(),
      );

      await prefs.setString(_userKey, userToJson(user));
      return user;
    } catch (e) {
      return null;
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email adresi gereklidir');
      }

      if (!email.contains('@')) {
        throw Exception('Geçerli bir email adresi giriniz');
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Şifre sıfırlama başarısız';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        default:
          errorMessage = 'Şifre sıfırlama başarısız: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Şifre sıfırlama başarısız: ${e.toString()}');
    }
  }

  // Doktor listesini getir
  Future<List<models.User>> getDoctors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKeys = prefs
          .getKeys()
          .where((key) => key.startsWith('user_'))
          .toList();

      final List<models.User> doctors = [];

      for (String key in userKeys) {
        final userJson = prefs.getString(key);
        if (userJson != null) {
          final user = userFromJson(userJson);
          if (user.userType == models.UserType.doctor) {
            doctors.add(user);
          }
        }
      }

      return doctors;
    } catch (e) {
      return [];
    }
  }

  // Tüm kullanıcıları getir
  Future<List<models.User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKeys = prefs
          .getKeys()
          .where((key) => key.startsWith('user_'))
          .toList();

      final List<models.User> users = [];

      for (String key in userKeys) {
        final userJson = prefs.getString(key);
        if (userJson != null) {
          final user = userFromJson(userJson);
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  // JSON helper methods
  String userToJson(models.User user) {
    return '${user.id}|${user.name}|${user.email}|${user.phone}|${user.userType.toString().split('.').last}|${user.specialty ?? ''}|${user.createdAt.toIso8601String()}';
  }

  models.User userFromJson(String json) {
    final parts = json.split('|');
    return models.User(
      id: parts[0],
      name: parts[1],
      email: parts[2],
      phone: parts[3],
      userType: models.UserType.values.firstWhere(
        (e) => e.toString().split('.').last == parts[4],
        orElse: () => models.UserType.patient,
      ),
      specialty: parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null,
      createdAt: DateTime.parse(parts[6]),
    );
  }
}
