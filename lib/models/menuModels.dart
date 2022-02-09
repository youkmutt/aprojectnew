import 'dart:convert';

Menu menuFromJson(String str) => Menu.fromJson(json.decode(str));

String menuToJson(Menu data) => json.encode(data.toJson());

class Menu {
  String Name;
  String MenuAction;
  String MenuController;
  String MenuIcon;
  String Child;

  Menu({
    this.Name,
    this.MenuAction,
    this.MenuController,
    this.MenuIcon,
    this.Child,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
    Name: json['Name'],
    MenuAction: json['MenuAction'],
    MenuController: json['MenuController'],
    MenuIcon: json['MenuIcon'],
    Child: json['Child'],
  );

  Map<String, dynamic> toJson() => {
    'Name': Name,
    'MenuAction': MenuAction,
    'MenuController': MenuController,
    'MenuIcon': MenuIcon,
    'Child': Child
  };
}