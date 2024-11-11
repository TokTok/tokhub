import 'dart:convert';

import 'package:github/github.dart';
import 'package:objectbox/objectbox.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/check_status.dart';

const _logger = Logger(['GitHubModels']);

final class MinimalCheckRun {
  final int id;
  final String name;
  final String headSha;
  final String detailsUrl;
  final CheckStatusConclusion conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const MinimalCheckRun({
    required this.id,
    required this.name,
    required this.headSha,
    required this.detailsUrl,
    required this.conclusion,
    required this.startedAt,
    required this.completedAt,
  });

  const MinimalCheckRun.empty()
      : id = 0,
        name = '',
        headSha = '',
        detailsUrl = '',
        conclusion = CheckStatusConclusion.empty,
        startedAt = null,
        completedAt = null;

  factory MinimalCheckRun.fromJson(Map<String, dynamic> json) =>
      MinimalCheckRun(
        id: json['id'] as int,
        name: json['name'] as String,
        headSha: json['head_sha'] as String,
        detailsUrl: json['details_url'] as String,
        conclusion: CheckStatusConclusion.values.firstWhere(
          (e) => e.string == json['conclusion'],
          orElse: () {
            _logger.w('Unknown check run conclusion: ${json['conclusion']}');
            return CheckStatusConclusion.unknown;
          },
        ),
        startedAt: json['started_at'] == null
            ? null
            : DateTime.parse(json['started_at'] as String),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
      );

  MinimalCheckRun copyWith({int? id, String? headSha}) => MinimalCheckRun(
        id: id ?? this.id,
        name: name,
        headSha: headSha ?? this.headSha,
        detailsUrl: detailsUrl,
        conclusion: conclusion,
        startedAt: startedAt,
        completedAt: completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'head_sha': headSha,
        'details_url': detailsUrl,
        'conclusion': conclusion.string,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };
}

final class MinimalPullRequest {
  final int id;
  final int number;
  final bool draft;
  final String title;
  final String mergeableState;
  final String htmlUrl;
  final MinimalPullRequestHead head;
  final MinimalUser user;
  final DateTime? updatedAt;

  const MinimalPullRequest({
    required this.id,
    required this.number,
    required this.draft,
    required this.title,
    required this.mergeableState,
    required this.htmlUrl,
    required this.head,
    required this.user,
    required this.updatedAt,
  });

  const MinimalPullRequest.empty()
      : id = 0,
        number = 0,
        draft = false,
        title = '',
        mergeableState = '',
        htmlUrl = '',
        head = const MinimalPullRequestHead.empty(),
        user = const MinimalUser.empty(),
        updatedAt = null;

  factory MinimalPullRequest.fromJson(Map<String, dynamic> json) =>
      MinimalPullRequest(
        id: json['id'] as int,
        number: json['number'] as int,
        draft: json['draft'] as bool,
        title: json['title'] as String,
        mergeableState: json['mergeable_state'] as String,
        htmlUrl: json['html_url'] as String,
        head: MinimalPullRequestHead.fromJson(json['head']),
        user: MinimalUser.fromJson(json['user']),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  MinimalPullRequest copyWith({
    int? id,
    int? number,
    bool? draft,
    String? title,
    String? mergeableState,
    String? htmlUrl,
    MinimalPullRequestHead? head,
    MinimalUser? user,
    DateTime? updatedAt,
  }) =>
      MinimalPullRequest(
        id: id ?? this.id,
        number: number ?? this.number,
        draft: draft ?? this.draft,
        title: title ?? this.title,
        mergeableState: mergeableState ?? this.mergeableState,
        htmlUrl: htmlUrl ?? this.htmlUrl,
        head: head ?? this.head,
        user: user ?? this.user,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'draft': draft,
        'title': title,
        'mergeable_state': mergeableState,
        'html_url': htmlUrl,
        'head': head.toJson(),
        'user': user.toJson(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

final class MinimalPullRequestHead {
  final String ref;
  final String sha;

  const MinimalPullRequestHead({
    required this.ref,
    required this.sha,
  });

  const MinimalPullRequestHead.empty()
      : ref = '',
        sha = '';

  factory MinimalPullRequestHead.fromJson(Map<String, dynamic> json) =>
      MinimalPullRequestHead(
        ref: json['ref'] as String,
        sha: json['sha'] as String,
      );

  MinimalPullRequestHead copyWith({String? ref, String? sha}) =>
      MinimalPullRequestHead(
        ref: ref ?? this.ref,
        sha: sha ?? this.sha,
      );

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'sha': sha,
      };
}

final class MinimalUser {
  final String login;
  final String avatarUrl;

  const MinimalUser({
    required this.login,
    required this.avatarUrl,
  });

  const MinimalUser.empty()
      : login = '',
        avatarUrl = '';

  factory MinimalUser.fromJson(Map<String, dynamic> json) => MinimalUser(
        login: json['login'] as String,
        avatarUrl: json['avatar_url'] as String,
      );

  MinimalUser copyWith({
    String? login,
    String? avatarUrl,
  }) =>
      MinimalUser(
        login: login ?? this.login,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        'login': login,
        'avatar_url': avatarUrl,
      };
}

/// [CheckRun]
@Entity()
final class StoredCheckRun {
  @Transient()
  MinimalCheckRun data = const MinimalCheckRun.empty();

  @Id(assignable: true)
  int get id => data.id;
  set id(int value) => data = data.copyWith(id: value);

  String get json => jsonEncode(data.toJson());
  set json(String value) => data = MinimalCheckRun.fromJson(jsonDecode(value));

  @Index()
  String? get sha => data.headSha;
  set sha(String? value) {}
}

/// [CombinedRepositoryStatus]
@Entity()
final class StoredCombinedRepositoryStatus {
  @Transient()
  CombinedRepositoryStatus data = CombinedRepositoryStatus();

  @Id()
  int id = 0;

  String get json => jsonEncode(data.toJson());
  set json(String value) =>
      data = CombinedRepositoryStatus.fromJson(jsonDecode(value));

  @Index()
  String? get repo => data.repository?.fullName;
  set repo(String? value) =>
      value == null ? null : data.repository?.fullName = value;

  @Index()
  String? get sha => data.sha;
  set sha(String? value) => data.sha = value;
}

/// [PullRequest]
@Entity()
final class StoredPullRequest {
  @Transient()
  MinimalPullRequest data = const MinimalPullRequest.empty();

  final repo = ToOne<StoredRepository>();

  @Id(assignable: true)
  int get id => data.id;
  set id(int value) => data = data.copyWith(id: value);

  String get json => jsonEncode(data.toJson());
  set json(String value) =>
      data = MinimalPullRequest.fromJson(jsonDecode(value));
}

/// [Repository]
@Entity()
final class StoredRepository {
  @Transient()
  Repository data = Repository();

  final pullRequests = ToMany<StoredPullRequest>();
  @Id(assignable: true)
  int get id => data.id;

  set id(int value) => data.id = value;

  String get json => jsonEncode(data.toJson());
  set json(String value) => data = Repository.fromJson(jsonDecode(value));
}
