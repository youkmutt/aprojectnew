import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  String username;
  String password;
  int remember;
  String ID;
  String FirstName;
  String LastName;
  String FullName;
  int RoleID;
  String RoleName;
  String UserProfileImage;
  String Email;
  String Token;
  String EmployeeID;

  User({
    this.username,
    this.password,
    this.remember,
    this.ID,
    this.FirstName,
    this.LastName,
    this.FullName,
    this.RoleID,
    this.RoleName,
    this.UserProfileImage,
    this.Email,
    this.Token,
    this.EmployeeID
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    password: json['password'],
    remember: json['remember'],
    ID: json['ID'],
    FirstName: json['FirstName'],
    LastName: json['LastName'],
    FullName: json['FullName'],
    RoleID: json['RoleID'],
    RoleName: json['RoleName'],
    UserProfileImage: json['UserProfileImage'],
    Email: json['Email'],
    Token: json['Token'],
    EmployeeID: json['EmployeeID'],
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'remember': remember,
    'ID': ID,
    'FirstName': FirstName,
    'LastName': LastName,
    'FullName': FullName,
    'RoleID': RoleID,
    'RoleName': RoleName,
    'UserProfileImage': UserProfileImage,
    'Email': Email,
    'Token': Token,
    'EmployeeID': EmployeeID,
  };
}