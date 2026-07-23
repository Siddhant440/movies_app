class AppUser {
  final String localId;
  final int? remoteId;
  final String firstName;
  final String lastName;
  final String email;
  final String avatar;
  final bool isSynced;
  final int savedCount;

  const AppUser({
    required this.localId,
    this.remoteId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatar,
    this.isSynced = false,
    this.savedCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get movieTaste => email;

  /// True for the demo accounts pulled from the reqres.in test API (used
  /// elsewhere purely to simulate a sync backend) - they use a plain
  /// numeric id as localId. Real profiles created via Add Profile get a
  /// uuid, which never parses as an int. Used to keep "top pick" (saved by
  /// everyone) meaningful - it shouldn't require every unused demo account
  /// to save a movie too, just every real profile.
  bool get isDemoProfile => int.tryParse(localId) != null;

  factory AppUser.fromReqresJson(Map<String, dynamic> json) {
    final remoteId = int.tryParse((json['id'] ?? '').toString());

    return AppUser(
      localId: json['id']?.toString() ?? '',
      remoteId: remoteId,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      isSynced: true,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'localId': localId,
      'remoteId': remoteId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'avatar': avatar,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory AppUser.fromLocalMap(Map<String, dynamic> map) {
    return AppUser(
      localId: map['localId'] as String,
      remoteId: map['remoteId'] as int?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String? ?? '',
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      savedCount: map['savedCount'] as int? ?? 0,
    );
  }

  AppUser copyWith({int? savedCount, bool? isSynced}) {
    return AppUser(
      localId: localId,
      remoteId: remoteId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      avatar: avatar,
      isSynced: isSynced ?? this.isSynced,
      savedCount: savedCount ?? this.savedCount,
    );
  }
}
