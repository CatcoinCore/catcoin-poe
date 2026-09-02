/// Typed parsing for auth JSON bodies (backend contract).

class SignupAck {
  final String message;

  const SignupAck({required this.message});

  /// `POST /auth/signup` returns only `{ "message": "..." }` (no user object).
  factory SignupAck.fromJson(Map<String, dynamic> json) {
    final m = json['message'];
    if (m is! String || m.isEmpty) {
      throw const FormatException(
        'Invalid signup response: expected non-empty message string',
      );
    }
    return SignupAck(message: m);
  }
}

/// Access + refresh pair from login, verify-email, or refresh.
class AuthTokenPayload {
  final String accessToken;
  final String refreshToken;

  const AuthTokenPayload({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokenPayload.fromJson(Map<String, dynamic> json) {
    final a = json['access_token'];
    final r = json['refresh_token'];
    if (a is! String ||
        a.isEmpty ||
        r is! String ||
        r.isEmpty) {
      throw const FormatException(
        'Invalid token response: expected access_token and refresh_token strings',
      );
    }
    return AuthTokenPayload(accessToken: a, refreshToken: r);
  }
}
