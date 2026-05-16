import 'package:hive/hive.dart';

part 'transcript_model.g.dart';

@HiveType(typeId: 0)
class TranscriptModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final int durationSeconds;

  TranscriptModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.durationSeconds,
  });
}