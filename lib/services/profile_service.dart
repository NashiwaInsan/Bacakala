import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'auth_service.dart';

class ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Ambil profil milik user yang sedang login (null jika belum ada barisnya).
  Future<Profile?> getMyProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data == null ? null : Profile.fromJson(data);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}
