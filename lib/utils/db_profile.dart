import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import 'package:aprojectnew/models/user.dart';

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
        join(await getDatabasesPath(), 'profile.db'),
        onCreate: (db, version) async{
          await db.execute('CREATE TABLE users ('
              'username TEXT,'
              'password TEXT,'
              'remember integers,'
              'ID TEXT,'
              'FirstName TEXT,'
              'LastName TEXT,'
              'FullName TEXT,'
              'RoleID integers,'
              'RoleName TEXT,'
              'UserProfileImage TEXT,'
              'Email TEXT,'
              'Token TEXT,'
              'EmployeeID TEXT'
              ')');
        },
        version: 1
    );
  }

  newUser(User newUser) async {
    Database db = await database;
    var res = await db.rawInsert('INSERT INTO users (username,password,remember,ID,FirstName,LastName,FullName,RoleID,RoleName,UserProfileImage,Email,Token,EmployeeID) '
        'VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [newUser.username,newUser.password,newUser.remember,
          newUser.ID,newUser.FirstName,newUser.LastName,
          newUser.FullName,newUser.RoleID,newUser.RoleName,
          newUser.UserProfileImage,newUser.Email,newUser.Token,newUser.EmployeeID]);
    return res;
  }

  Future<User> getUser() async {
    Database db = await database;
    var res = await db.query('users');
    if(res.length == 0){
      return null;
    } else{
      var rest = res[0];

      var resMap = User(
        username: rest['username'],
        password: rest['password'],
        remember: rest['remember'],
        ID: rest['ID'],
        FirstName: rest['FirstName'],
        LastName: rest['LastName'],
        FullName: rest['FullName'],
        RoleID: rest['RoleID'],
        RoleName: rest['RoleName'],
        UserProfileImage: rest['UserProfileImage'],
        Email: rest['Email'],
        Token: rest['Token'],
        EmployeeID: rest['EmployeeID'],
      );

      return rest.isNotEmpty ? resMap : Null;
    }
  }

  Future<int> deleteUser() async {
    Database db = await database;
    return db.delete('users');
  }
  Future<void> dropUser() async {
    databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'profile.db'));
    //await db.rawQuery('DROP TABLE users;');
  }


}