import '../../../core/api/api_response.dart';

final class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.weight,
    this.dailyWaterGoal,
    this.dailyKcalGoal,
  });
  final String id, name, email;
  final double? weight;
  final int? dailyWaterGoal, dailyKcalGoal;
  factory UserProfile.fromJson(JsonMap json) => UserProfile(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    weight: (json['weight'] as num?)?.toDouble(),
    dailyWaterGoal: (json['daily_water_goal'] as num?)?.toInt(),
    dailyKcalGoal: (json['daily_kcal_goal'] as num?)?.toInt(),
  );
}

final class AuthSession {
  const AuthSession(this.user);
  final UserProfile? user;
}

final class LoginCommand {
  const LoginCommand({
    required this.email,
    required this.password,
    this.deviceName = 'fitness_app',
  });
  final String email, password, deviceName;
  JsonMap toJson() => {
    'email': email.trim(),
    'password': password,
    'device_name': deviceName,
  };
}

final class RegisterCommand {
  const RegisterCommand({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name, email, password;
  JsonMap toJson() => {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
    'password_confirmation': password,
  };
}
