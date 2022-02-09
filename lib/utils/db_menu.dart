import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import 'package:aprojectnew/models/menuModels.dart';

class DBProvider{
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;

  Future<Database> get database async {
    if(_database != null)
      return _database;

    //databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'profile.db'));
    _database = await initDB();
    return _database;
  }

  initDB() async {
    return await openDatabase(
        join(await getDatabasesPath(), 'menus.db'),
        onCreate: (db, version) async{
          await db.execute('CREATE TABLE menus ('
              'Name TEXT,'
              'MenuAction TEXT,'
              'MenuController TEXT,'
              'MenuIcon TEXT,'
              'Child TEXT'
              ')');
        },
        version: 1
    );
  }

  newMenu(Menu newMenu) async {
    Database db = await database;
    var res = await db.rawInsert('INSERT INTO menus (Name,MenuAction,MenuController,MenuIcon,Child) '
        'VALUES(?,?,?,?,?)',
        [newMenu.Name,newMenu.MenuAction,newMenu.MenuController,newMenu.MenuIcon,newMenu.Child]);
    return res;
  }

  Future<List<Menu>> getMenu() async {
    Database db = await database;
    var res = await db.query('menus');
    if(res.length == 0){
      return null;
    } else{
      List<Menu> menuList = [];

      for(var rest in res){
        menuList.add(Menu(
          Name: rest['Name'],
          MenuAction: rest['MenuAction'],
          MenuController: rest['MenuController'],
          MenuIcon: rest['MenuIcon'],
          Child: rest['Child'],
        ));
      }

      return menuList.isNotEmpty ? menuList : Null;
    }
  }

  Future<int> deleteMenu() async {
    Database db = await database;
    return db.delete('menus');
  }
  Future<void> dropMenu() async {
    databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'menus.db'));
    //await db.rawQuery('DROP TABLE users;');
  }


}