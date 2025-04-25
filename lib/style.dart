import 'package:flutter/material.dart';

// 다른파일에서 임포트해도 가져다 쓰지 못하게 _ 를 붙임
var _var1;

var theme = ThemeData(
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(
        size: 40,
      ),
      elevation: 1,
    ),
    textButtonTheme: TextButtonThemeData(
        style:TextButton.styleFrom(
          backgroundColor: Colors.blue,
        )
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 15,
      unselectedItemColor: Colors.black38,
      selectedItemColor: Colors.black,
    ),



);
