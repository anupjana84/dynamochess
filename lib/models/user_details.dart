import 'package:shared_preferences/shared_preferences.dart';

class UserDetail {
  // Renamed from MockUserDetail
  final String id; // Changed from _id to id
  final String name;
  final int dynamoCoin;
  final String? countryIcon; // Made nullable as it might be null from prefs
  final double rating;
  final String? email;
  final String? role;
  final String? mobile;
  final String? country;
  final String? token;

  UserDetail({
    required this.id,
    required this.name,
    required this.dynamoCoin,
    this.countryIcon,
    required this.rating,
    this.email,
    this.role,
    this.mobile,
    this.country,
    this.token,
  });

  // Factory constructor to create UserDetail from SharedPreferences gg
  factory UserDetail.fromSharedPreferences(SharedPreferences prefs) {
    return UserDetail(
      id: prefs.getString('_id') ??
          '', // Provide a default empty string if null
      name: prefs.getString('name') ?? 'Guest',
      dynamoCoin: prefs.getInt('dynamoCoin') ?? 0,
      countryIcon: prefs.getString('countryIcon'),
      rating: (prefs.getDouble('Rating') ?? 0)
          .toDouble(), // Rating is int in prefs, convert to double
      email: prefs.getString('email'),
      role: prefs.getString('role'),
      mobile: prefs.getString('mobile'),
      country: prefs.getString('country'),
      token: prefs.getString('token'),
    );
  }

  // Factory constructor for an empty/default user
  factory UserDetail.empty() {
    return UserDetail(
      id: '',
      name: 'Guest',
      dynamoCoin: 0,
      countryIcon: null,
      rating: 0.0,
      email: null,
      role: null,
      mobile: null,
      country: null,
      token: null,
    );
  }
}
