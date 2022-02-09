import 'dart:convert';

Environment userFromJson(String str) => Environment.fromJson(json.decode(str));

String userToJson(Environment data) => json.encode(data.toJson());

class Environment {
  String module;
  String target;
  String url;

  Environment({
    this.module,
    this.target,
    this.url,
  });

  factory Environment.fromJson(Map<String, dynamic> json) => Environment(
    module: json['username'],
    target: json['password'],
    url: json['remember'],
  );

  Map<String, dynamic> toJson() => {
    'module': module,
    'target': target,
    'url': url,
  };
}