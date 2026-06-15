class LesEvaluatie {
  final String id;
  final String lessonId;
  final String studentId;
  final String instructorId;
  final String rating;
  final String? feedback;
  final List<String> focusPoints;
  final String interventionCount;
  final String? nextLessonAdvice;
  final String createdAt;
  final List<LesSkillScore> skillScores;

  const LesEvaluatie({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.instructorId,
    required this.rating,
    this.feedback,
    this.focusPoints = const [],
    this.interventionCount = 'geen',
    this.nextLessonAdvice,
    required this.createdAt,
    this.skillScores = const [],
  });

  String get ratingLabel => switch (rating) {
        'moeizaam' => 'Moeizaam',
        'voldoende' => 'Voldoende',
        'goed' => 'Goed',
        'uitstekend' => 'Uitstekend',
        _ => rating,
      };

  String get interventionLabel => switch (interventionCount) {
        'geen' => 'Geen',
        'een_keer' => 'Één keer',
        'meerdere_keren' => 'Meerdere keren',
        _ => interventionCount,
      };

  factory LesEvaluatie.fromJson(Map<String, dynamic> json) {
    final scoresRaw = json['skill_scores'] as List<dynamic>? ?? [];
    return LesEvaluatie(
      id: json['id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      instructorId: json['instructor_id'] as String? ?? '',
      rating: json['rating'] as String? ?? 'voldoende',
      feedback: json['feedback'] as String?,
      focusPoints: _stringList(json['focus_points']),
      interventionCount: json['intervention_count'] as String? ?? 'geen',
      nextLessonAdvice: json['next_lesson_advice'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      skillScores:
          scoresRaw.map((s) => LesSkillScore.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class LesSkillScore {
  final String id;
  final String skillKey;
  final int score;

  const LesSkillScore({
    required this.id,
    required this.skillKey,
    required this.score,
  });

  factory LesSkillScore.fromJson(Map<String, dynamic> json) {
    return LesSkillScore(
      id: json['id'] as String? ?? '',
      skillKey: json['skill_key'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}
