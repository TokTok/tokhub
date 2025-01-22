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
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
  TextColumn get repoSlug => text().nullable()();
  @JsonKey('started_at')
  DateTimeColumn get startedAt => dateTime().nullable()();
}

class MinimalCommitStatus extends Table {
  TextColumn get context => text()();
  TextColumn get description => text().nullable()();
  TextColumn get headSha => text().nullable()();
  IntColumn get id => integer().autoIncrement()();
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
  TextColumn get repoSlug => text().nullable()();
  TextColumn get state => text()();
  TextColumn get targetUrl => text().nullable()();
}

class MinimalIssue extends Table {
  TextColumn get body => text().nullable()();
  @JsonKey('closed_at')
  DateTimeColumn get closedAt => dateTime().nullable()();
  @JsonKey('created_at')
  DateTimeColumn get createdAt => dateTime().nullable()();
  @JsonKey('html_url')
  TextColumn get htmlUrl => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get milestone =>
      text().nullable().map(const MinimalMilestoneConverter())();
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
  IntColumn get number => integer()();
  IntColumn get parent => integer().nullable()();
  @JsonKey('pull_request')
  TextColumn get pullRequest =>
      text().nullable().map(const MinimalIssuePullRequestConverter())();
  TextColumn get repoSlug => text().nullable()();
  TextColumn get state => text()();
  @JsonKey('sub_issues_summary')
  TextColumn get subIssuesSummary =>
      text().map(const MinimalIssueSubIssuesSummaryConverter())();
  TextColumn get title => text()();
  @JsonKey('updated_at')
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get user => text().map(const MinimalUserConverter())();
}

final class MinimalIssuePullRequest {
  final Uri url;
  final Uri htmlUrl;

  const MinimalIssuePullRequest({
    required this.url,
    required this.htmlUrl,
  });

  factory MinimalIssuePullRequest.fromJson(Map<String, dynamic> map) {
    return MinimalIssuePullRequest(
      url: Uri.parse(map['url'] as String),
      htmlUrl: Uri.parse(map['html_url'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url.toString(),
      'html_url': htmlUrl.toString(),
    };
  }
}

final class MinimalIssuePullRequestConverter
    extends TypeConverter<MinimalIssuePullRequest?, String?>
    with
        JsonTypeConverter2<MinimalIssuePullRequest?, String?,
            Map<String, dynamic>?> {
  const MinimalIssuePullRequestConverter();

  @override
  MinimalIssuePullRequest? fromJson(Map<String, dynamic>? json) {
    return json == null ? null : MinimalIssuePullRequest.fromJson(json);
  }

  @override
  MinimalIssuePullRequest? fromSql(String? fromDb) {
    return fromDb == null ? null : fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic>? toJson(MinimalIssuePullRequest? value) {
    return value?.toJson();
  }

  @override
  String? toSql(MinimalIssuePullRequest? value) {
    return value == null ? null : jsonEncode(toJson(value));
  }
}

final class MinimalIssueSubIssuesSummary {
  final int total;
  final int completed;

  const MinimalIssueSubIssuesSummary({
    required this.total,
    required this.completed,
  });

  factory MinimalIssueSubIssuesSummary.fromJson(Map<String, dynamic> map) {
    return MinimalIssueSubIssuesSummary(
      total: map['total'] as int,
      completed: map['completed'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'completed': completed,
    };
  }
}

final class MinimalIssueSubIssuesSummaryConverter
    extends TypeConverter<MinimalIssueSubIssuesSummary, String>
    with
        JsonTypeConverter2<MinimalIssueSubIssuesSummary, String,
            Map<String, dynamic>> {
  const MinimalIssueSubIssuesSummaryConverter();

  @override
  MinimalIssueSubIssuesSummary fromJson(Map<String, dynamic> json) {
    return MinimalIssueSubIssuesSummary.fromJson(json);
  }

  @override
  MinimalIssueSubIssuesSummary fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic> toJson(MinimalIssueSubIssuesSummary value) {
    return value.toJson();
  }

  @override
  String toSql(MinimalIssueSubIssuesSummary value) {
    return jsonEncode(toJson(value));
  }
}

class MinimalMilestone extends Table {
  TextColumn get description => text().nullable()();
  @JsonKey('html_url')
  TextColumn get htmlUrl => text()();
  IntColumn get id => integer().autoIncrement()();
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
  TextColumn get state => text()();
  TextColumn get title => text()();
}

final class MinimalMilestoneConverter
    extends TypeConverter<MinimalMilestoneData?, String?>
    with
        JsonTypeConverter2<MinimalMilestoneData?, String?,
            Map<String, dynamic>?> {
  const MinimalMilestoneConverter();

  @override
  MinimalMilestoneData? fromJson(Map<String, dynamic>? json) {
    return json == null ? null : MinimalMilestoneData.fromJson(json);
  }

  @override
  MinimalMilestoneData? fromSql(String? fromDb) {
    return fromDb == null ? null : fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic>? toJson(MinimalMilestoneData? value) {
    return value?.toJson();
  }

  @override
  String? toSql(MinimalMilestoneData? value) {
    return value == null ? null : jsonEncode(toJson(value));
  }
}

final class MinimalNotificationData {
  final int id;
  final bool unread;
  final String reason;
  final DateTime updatedAt;
  final MinimalNotificationSubject subject;
  final MinimalRepositoryData repository;
  final Uri url;

  const MinimalNotificationData({
    required this.id,
    required this.unread,
    required this.reason,
    required this.updatedAt,
    required this.subject,
    required this.repository,
    required this.url,
  });

  factory MinimalNotificationData.fromJson(Map<String, dynamic> map) {
    return MinimalNotificationData(
      id: int.parse(map['id'] as String),
      unread: map['unread'] as bool,
      reason: map['reason'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      subject: MinimalNotificationSubject.fromJson(
          map['subject'] as Map<String, dynamic>),
      repository: MinimalRepositoryData.fromJson(
          map['repository'] as Map<String, dynamic>),
      url: Uri.parse(map['url'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unread': unread,
      'reason': reason,
      'updated_at': updatedAt.toIso8601String(),
      'subject': subject.toJson(),
      'repository': repository.toJson(),
      'url': url.toString(),
    };
  }
}

enum MinimalNotificationSubjectType
    implements JsonEnum<MinimalNotificationSubjectType> {
  discussion('Discussion', 'discussions', '💬'),
  issue('Issue', 'issues', '🐛'),
  pullRequest('PullRequest', 'pull', '🛠️');

  @override
  final String string;
  final String path;
  final String emoji;

  const MinimalNotificationSubjectType(this.string, this.path, this.emoji);
}

final class MinimalNotificationSubject {
  static const typeConverter =
      JsonEnumConverter(MinimalNotificationSubjectType.values);

  final String title;
  final MinimalNotificationSubjectType type;
  final Uri? url;
  final Uri? latestCommentUrl;

  const MinimalNotificationSubject({
    required this.title,
    required this.type,
    required this.url,
    this.latestCommentUrl,
  });

  factory MinimalNotificationSubject.fromJson(Map<String, dynamic> map) {
    return MinimalNotificationSubject(
      title: map['title'] as String,
      type: typeConverter.fromJson(map['type'] as String),
      url: map['url'] == null ? null : Uri.parse(map['url'] as String),
      latestCommentUrl: map['latest_comment_url'] == null
          ? null
          : Uri.parse(map['latest_comment_url'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': typeConverter.toJson(type),
      'url': url?.toString(),
      'latest_comment_url': latestCommentUrl?.toString(),
    };
  }
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
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
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

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'sha': sha,
      'repo': repo.toJson(),
    };
  }
}

final class MinimalPullRequestHeadConverter
    extends TypeConverter<MinimalPullRequestHead, String>
    with
        JsonTypeConverter2<MinimalPullRequestHead, String,
            Map<String, dynamic>> {
  const MinimalPullRequestHeadConverter();

  @override
  MinimalPullRequestHead fromJson(Map<String, dynamic> json) {
    return MinimalPullRequestHead.fromJson(json);
  }

  @override
  MinimalPullRequestHead fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic> toJson(MinimalPullRequestHead value) {
    return value.toJson();
  }

  @override
  String toSql(MinimalPullRequestHead value) {
    return jsonEncode(toJson(value));
  }
}

class MinimalRepository extends Table {
  TextColumn get description => text().nullable()();
  @JsonKey('full_name')
  TextColumn get fullName => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
  TextColumn get owner => text().map(const MinimalUserConverter())();
}

class MinimalUser extends Table {
  @JsonKey('avatar_url')
  TextColumn get avatarUrl => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get login => text()();
  @JsonKey('node_id')
  TextColumn get nodeId => text()();
}

final class MinimalUserConverter extends TypeConverter<MinimalUserData, String>
    with JsonTypeConverter2<MinimalUserData, String, Map<String, dynamic>> {
  const MinimalUserConverter();

  @override
  MinimalUserData fromJson(Map<String, dynamic> json) {
    return MinimalUserData.fromJson(json);
  }

  @override
  MinimalUserData fromSql(String fromDb) {
    return fromJson(jsonDecode(fromDb));
  }

  @override
  Map<String, dynamic> toJson(MinimalUserData value) {
    return value.toJson();
  }

  @override
  String toSql(MinimalUserData value) {
    return jsonEncode(toJson(value));
  }
}

extension MinimalRepositoryExtension on MinimalRepositoryData {
  RepositorySlug slug() => RepositorySlug(owner.login, name);
}
