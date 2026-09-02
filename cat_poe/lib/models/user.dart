class User {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String referralCode;
  final String? referredBy;
  final String? referredByDisplayName; // Referrer's display name for UI
  final double balance;
  final String country;
  final String? countrySource;
  final bool emailVerified;
  final DateTime createdAt;
  final bool isAdmin;
  final String? discordId;
  final bool discordIdVerified;
  final bool discordIdLocked;
  final String? telegramId;
  final bool telegramIdVerified;
  final bool telegramIdLocked;
  final String? xId;
  final bool xIdVerified;
  final bool xIdLocked;
  final String? facebookId;
  final bool facebookIdVerified;
  final bool facebookIdLocked;
  final String? whatsappId;
  final bool whatsappIdVerified;
  final bool whatsappIdLocked;
  /// Earned badge IDs to display on profile (max 6), in order.
  final List<String> showcaseBadgeIds;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    required this.referralCode,
    this.referredBy,
    this.referredByDisplayName,
    required this.balance,
    required this.country,
    this.countrySource,
    required this.emailVerified,
    required this.createdAt,
    this.isAdmin = false,
    this.discordId,
    this.discordIdVerified = false,
    this.discordIdLocked = false,
    this.telegramId,
    this.telegramIdVerified = false,
    this.telegramIdLocked = false,
    this.xId,
    this.xIdVerified = false,
    this.xIdLocked = false,
    this.facebookId,
    this.facebookIdVerified = false,
    this.facebookIdLocked = false,
    this.whatsappId,
    this.whatsappIdVerified = false,
    this.whatsappIdLocked = false,
    this.showcaseBadgeIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> showcase = const [];
    final rawShow = json['showcase_badge_ids'];
    if (rawShow is List) {
      showcase = rawShow.map((e) => e.toString()).toList();
    }
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      referralCode: json['referral_code'] as String,
      referredBy: json['referred_by'] as String?,
      referredByDisplayName: json['referred_by_display_name'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      country: json['country'] as String? ?? 'US',
      countrySource: json['country_source'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAdmin: json['is_admin'] as bool? ?? false,
      discordId: json['discord_id'] as String?,
      discordIdVerified: json['discord_id_verified'] as bool? ?? false,
      discordIdLocked: json['discord_id_locked'] as bool? ?? false,
      telegramId: json['telegram_id'] as String?,
      telegramIdVerified: json['telegram_id_verified'] as bool? ?? false,
      telegramIdLocked: json['telegram_id_locked'] as bool? ?? false,
      xId: json['x_id'] as String?,
      xIdVerified: json['x_id_verified'] as bool? ?? false,
      xIdLocked: json['x_id_locked'] as bool? ?? false,
      facebookId: json['facebook_id'] as String?,
      facebookIdVerified: json['facebook_id_verified'] as bool? ?? false,
      facebookIdLocked: json['facebook_id_locked'] as bool? ?? false,
      whatsappId: json['whatsapp_id'] as String?,
      whatsappIdVerified: json['whatsapp_id_verified'] as bool? ?? false,
      whatsappIdLocked: json['whatsapp_id_locked'] as bool? ?? false,
      showcaseBadgeIds: showcase,
    );
  }
}


