import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  static final DatabaseHelper instace  = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _databaseName = 'habitos.db';
  static const int _databaseVersion = 1;
}