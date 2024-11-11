import 'dart:convert';

import 'package:github/github.dart';
import 'package:objectbox/objectbox.dart';
import 'package:tokhub/logger.dart';
import 'package:tokhub/models/check_status.dart';

const _logger = Logger(['GitHubModels']);

@Entity()
final class MinimalCheckRun {
  @Id(assignable: true)
  int id;
  String name;
  @Index()
  String headSha;
  String detailsUrl;
  @Property(type: PropertyType.date)
  DateTime? startedAt;
  @Property(type: PropertyType.date)
  DateTime? completedAt;

  @Transient()
  CheckStatusConclusion conclusion;
  MinimalCheckRun()
      : id = 0,
        name = '',
        headSha = '',
        detailsUrl = '',
        conclusion = CheckStatusConclusion.unknown,
        startedAt = null,
        completedAt = null;
  factory MinimalCheckRun.fromJson(Map<String, dynamic> json) {
    return MinimalCheckRun._(
      id: json['id'] as int,
      name: json['name'] as String,
      headSha: json['head_sha'] as String,
      detailsUrl: json['details_url'] as String,
      conclusion: CheckStatusConclusion.values.firstWhere(
        (e) => e.string == json['conclusion'],
        orElse: () {
          _logger.w(
              'Unknown check run conclusion in ${json['name']}: ${json['conclusion']}');
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
  }

  MinimalCheckRun._({
    required this.id,
    required this.name,
    required this.headSha,
    required this.detailsUrl,
    required this.conclusion,
    required this.startedAt,
    required this.completedAt,
  });

  String get conclusionStored => conclusion.name;

  set conclusionStored(String value) {
    conclusion =
        CheckStatusConclusion.values.firstWhere((e) => e.name == value);
  }
}

@Entity()
final class MinimalPullRequest {
  @Id(assignable: true)
  int id;
  int number;
  bool draft;
  String title;
  String mergeableState;
  String htmlUrl;

  @Transient()
  MinimalPullRequestHead head;
  final ToOne<MinimalUser> user;
  final ToOne<MinimalRepository> repo;

  @Property(type: PropertyType.date)
  DateTime? updatedAt;
  MinimalPullRequest()
      : id = 0,
        number = 0,
        draft = false,
        title = '',
        mergeableState = '',
        htmlUrl = '',
        head = const MinimalPullRequestHead.empty(),
        user = ToOne(),
        repo = ToOne(),
        updatedAt = null;

  factory MinimalPullRequest.fromJson(Map<String, dynamic> json) {
    return MinimalPullRequest._(
      id: json['id'] as int,
      number: json['number'] as int,
      draft: json['draft'] as bool,
      title: json['title'] as String,
      mergeableState: json['mergeable_state'] as String,
      htmlUrl: json['html_url'] as String,
      head: MinimalPullRequestHead.fromJson(json['head']),
      user: ToOne(target: MinimalUser.fromJson(json['user'])),
      repo: ToOne(target: MinimalRepository.fromJson(json['base']['repo'])),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  MinimalPullRequest._({
    required this.id,
    required this.number,
    required this.draft,
    required this.title,
    required this.mergeableState,
    required this.htmlUrl,
    required this.head,
    required this.user,
    required this.repo,
    required this.updatedAt,
  });

  String get headStored => jsonEncode(head.toJson());

  set headStored(String value) =>
      head = MinimalPullRequestHead.fromJson(jsonDecode(value));
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

  factory MinimalPullRequestHead.fromJson(Map<String, dynamic> json) {
    return MinimalPullRequestHead(
      ref: json['ref'] as String,
      sha: json['sha'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'sha': sha,
    };
  }
}

@Entity()
final class MinimalRepository {
  @Id(assignable: true)
  int id;
  String name;
  String fullName;
  String owner;
  String? description;

  final ToMany<MinimalPullRequest> pullRequests = ToMany();

  MinimalRepository()
      : id = 0,
        name = '',
        fullName = '',
        owner = '',
        description = '';

  factory MinimalRepository.fromJson(Map<String, dynamic> json) =>
      MinimalRepository._(
        id: json['id'] as int,
        name: json['name'] as String,
        fullName: json['full_name'] as String,
        owner: json['owner']['login'] as String,
        description: json['description'] as String?,
      );

  MinimalRepository._({
    required this.id,
    required this.name,
    required this.fullName,
    required this.owner,
    required this.description,
  });

  RepositorySlug slug() => RepositorySlug(owner, name);
}

@Entity()
final class MinimalUser {
  @Id(assignable: true)
  int id;
  String login;
  String avatarUrl;

  MinimalUser()
      : id = 0,
        login = '',
        avatarUrl = '';

  factory MinimalUser.fromJson(Map<String, dynamic> json) {
    return MinimalUser._(
      id: json['id'] as int,
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
    );
  }

  MinimalUser._({
    required this.id,
    required this.login,
    required this.avatarUrl,
  });
}

/// [CombinedRepositoryStatus]
@Entity()
final class MinimalCombinedRepositoryStatus {
  @Id()
  int id = 0;
  String? state;
  String? sha;
  int? totalCount;
  @Transient()
  List<RepositoryStatus>? statuses;

  final ToOne<MinimalRepository> repository;

  MinimalCombinedRepositoryStatus() : repository = ToOne();

  MinimalCombinedRepositoryStatus._({
    required this.id,
    required this.state,
    required this.sha,
    required this.totalCount,
    required this.statuses,
    required this.repository,
  });

  factory MinimalCombinedRepositoryStatus.fromJson(Map<String, dynamic> json) {
    return MinimalCombinedRepositoryStatus._(
      id: 0,
      state: json['state'] as String?,
      sha: json['sha'] as String?,
      totalCount: json['total_count'] as int?,
      statuses: (json['statuses'] as List<dynamic>)
          .map((e) => RepositoryStatus.fromJson(e))
          .toList(growable: false),
      repository: ToOne(target: MinimalRepository.fromJson(json['repository'])),
    );
  }

  String get statusesStored =>
      jsonEncode(statuses?.map((e) => e.toJson()).toList(growable: false));
  set statusesStored(String value) =>
      statuses = (jsonDecode(value) as List<dynamic>)
          .map((e) => RepositoryStatus.fromJson(e))
          .toList(growable: false);
}
