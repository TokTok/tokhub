import 'dart:convert';

import 'package:github/github.dart';
import 'package:objectbox/objectbox.dart';

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
