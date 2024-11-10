import 'dart:convert';

import 'package:github/github.dart';
import 'package:objectbox/objectbox.dart';

/// [PullRequest]
@Entity()
final class StoredPullRequest {
  @Transient()
  PullRequest data = PullRequest();

  final repo = ToOne<StoredRepository>();

  @Id(assignable: true)
  int get id => data.id ?? 0;
  set id(int value) => data.id = value;

  String get json => jsonEncode(data.toJson());
  set json(String value) => data = PullRequest.fromJson(jsonDecode(value));
}

/// [Repository]
@Entity()
final class StoredRepository {
  @Transient()
  Repository data = Repository();

  @Id(assignable: true)
  int get id => data.id;
  set id(int value) => data.id = value;

  final pullRequests = ToMany<StoredPullRequest>();

  String get json => jsonEncode(data.toJson());
  set json(String value) => data = Repository.fromJson(jsonDecode(value));
}

/// [CombinedRepositoryStatus]
@Entity()
final class StoredCombinedRepositoryStatus {
  @Transient()
  CombinedRepositoryStatus data = CombinedRepositoryStatus();

  @Id()
  int id = 0;

  @Index()
  String? get repo => data.repository?.fullName;
  set repo(String? value) =>
      value == null ? null : data.repository?.fullName = value;

  @Index()
  String? get sha => data.sha;
  set sha(String? value) => data.sha = value;

  String get json => jsonEncode(data.toJson());
  set json(String value) =>
      data = CombinedRepositoryStatus.fromJson(jsonDecode(value));
}

/// [CheckRun]
@Entity()
final class StoredCheckRun {
  @Transient()
  CheckRun? data;

  @Id(assignable: true)
  int get id => data!.id!;
  set id(int value) {}

  @Index()
  String? get sha => data?.headSha;
  set sha(String? value) {}

  String get json => jsonEncode(data?.toJson());
  set json(String value) => data = CheckRun.fromJson(jsonDecode(value));
}
