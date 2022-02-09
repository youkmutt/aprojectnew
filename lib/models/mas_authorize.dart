import 'dart:convert';

Authorize authorizeFromJson(String str) => Authorize.fromJson(json.decode(str));

String authorizeToJson(Authorize data) => json.encode(data.toJson());

class Authorize {
  String Platform;
  String App_Name;
  String App_Version;
  String App_URL;
  String App_Key;

  Authorize({
    this.Platform,
    this.App_Name,
    this.App_Version,
    this.App_URL,
    this.App_Key,
  });

  factory Authorize.fromJson(Map<String, dynamic> json) => Authorize(
    Platform: json['Platform'],
    App_Name: json['App_Name'],
    App_Version: json['App_Version'],
    App_URL: json['App_URL'],
    App_Key: json['App_Key'],
  );

  Map<String, dynamic> toJson() => {
    'Platform': Platform,
    'App_Name': App_Name,
    'App_Version': App_Version,
    'App_URL': App_URL,
    'App_Key': App_Key,
  };
}