import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:github/github.dart';
import 'package:tokhub/db/database.dart';
import 'package:tokhub/models/check_status.dart';
import 'package:tokhub/models/json_enum.dart';

class MinimalCheckRun extends Table {
  @JsonKey('completed_at')
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get conclusion => text()
      .nullable()
      .map(const JsonEnumConverter(CheckStatusConclusion.values))();
  @JsonKey('details_url')
  TextColumn get detailsUrl => text()();
  @JsonKey('head_sha')
  TextColumn get headSha => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get repoSlug => text().nullable()();
  @JsonKey('started_at')
  DateTimeColumn get startedAt => dateTime().nullable()();
}

class MinimalCommitStatus extends Table {
  TextColumn get context => text()();
  TextColumn get description => text().nullable()();
  TextColumn get headSha => text().nullable()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get repoSlug => text().nullable()();
  TextColumn get state => text()();
  TextColumn get targetUrl => text().nullable()();
}

class MinimalPullRequest extends Table {
  TextColumn get base => text().map(const MinimalPullRequestHeadConverter())();
  BoolColumn get draft => boolean()();
  TextColumn get head => text().map(const MinimalPullRequestHeadConverter())();
  @JsonKey('html_url')
  TextColumn get htmlUrl => text()();
  IntColumn get id => integer().autoIncrement()();
  @JsonKey('mergeable_state')
  TextColumn get mergeableState => text().nullable()();
  IntColumn get number => integer()();
  TextColumn get repoSlug => text().nullable()();
  TextColumn get title => text()();
  @JsonKey('updated_at')
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get user => text().map(const MinimalUserConverter())();
}

final class MinimalPullRequestHead {
  final String ref;
  final String sha;
  final MinimalRepositoryData repo;

  const MinimalPullRequestHead({
    required this.ref,
    required this.sha,
    required this.repo,
  });

  factory MinimalPullRequestHead.fromJson(Map<String, dynamic> map) {
    return MinimalPullRequestHead(
      ref: map['ref'] as String,
      sha: map['sha'] as String,
      repo: MinimalRepositoryData.fromJson(map['repo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'sha': sha,
        'repo': repo.toJson(),
      };
}

final class MinimalPullRequestHeadConverter
    extends TypeConverter<MinimalPullRequestHead, String>
    with
        JsonTypeConverter2<MinimalPullRequestHead, String,
            Map<String, dynamic>> {
  const MinimalPullRequestHeadConverter();

  @override
  MinimalPullRequestHead fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  String toSql(MinimalPullRequestHead value) {
    return jsonEncode(toJson(value));
  }

  @override
  MinimalPullRequestHead fromJson(Map<String, dynamic> json) {
    return MinimalPullRequestHead.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(MinimalPullRequestHead value) {
    return value.toJson();
  }
}

class MinimalRepository extends Table {
  TextColumn get description => text().nullable()();
  @JsonKey('full_name')
  TextColumn get fullName => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get owner => text().map(const MinimalUserConverter())();
}

class MinimalUser extends Table {
  @JsonKey('avatar_url')
  TextColumn get avatarUrl => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get login => text()();
}

final class MinimalUserConverter extends TypeConverter<MinimalUserData, String>
    with JsonTypeConverter2<MinimalUserData, String, Map<String, dynamic>> {
  const MinimalUserConverter();

  @override
  MinimalUserData fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  String toSql(MinimalUserData value) {
    return jsonEncode(toJson(value));
  }

  @override
  MinimalUserData fromJson(Map<String, dynamic> json) {
    return MinimalUserData.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(MinimalUserData value) {
    return value.toJson();
  }
}

extension MinimalRepositoryExtension on MinimalRepositoryData {
  RepositorySlug slug() => RepositorySlug(owner.login, name);
}
