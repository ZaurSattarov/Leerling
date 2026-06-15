enum AvatarCategory { male, female }

class AvatarOption {
  final String id;
  final String assetPath;
  final AvatarCategory category;

  const AvatarOption({
    required this.id,
    required this.assetPath,
    required this.category,
  });
}

class AvatarService {
  const AvatarService._();

  static const fallbackAvatarId = 'male_01';

  static final List<AvatarOption> _maleAvatars = List.generate(
    16,
    (index) {
      final number = (index + 1).toString().padLeft(2, '0');
      return AvatarOption(
        id: 'male_$number',
        assetPath: 'assets/avatars/male_$number.png',
        category: AvatarCategory.male,
      );
    },
  );

  static final List<AvatarOption> _femaleAvatars = List.generate(
    11,
    (index) {
      final number = (index + 1).toString().padLeft(2, '0');
      return AvatarOption(
        id: 'female_$number',
        assetPath: 'assets/avatars/female_$number.png',
        category: AvatarCategory.female,
      );
    },
  );

  static final List<AvatarOption> avatars = [
    ..._maleAvatars,
    ..._femaleAvatars,
  ];

  static AvatarOption? optionFor(String? avatarId) {
    final id = avatarId?.trim();
    if (id == null || id.isEmpty) return null;
    for (final avatar in avatars) {
      if (avatar.id == id) return avatar;
    }
    return null;
  }

  static bool isValid(String? avatarId) => optionFor(avatarId) != null;

  static String? assetPathFor(String? avatarId) =>
      optionFor(avatarId)?.assetPath;

  static String fallbackForName(String? name) {
    if (_maleAvatars.isEmpty) return fallbackAvatarId;
    final seed = (name ?? '').trim();
    if (seed.isEmpty) return fallbackAvatarId;
    final index =
        seed.codeUnits.fold<int>(0, (sum, v) => sum + v) % _maleAvatars.length;
    return _maleAvatars[index].id;
  }
}
